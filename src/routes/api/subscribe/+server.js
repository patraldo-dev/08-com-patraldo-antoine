// src/routes/api/subscribe/+server.js
import { getTranslation } from '$lib/i18n/server';

export async function POST({ request, platform }) {
  try {
    const { email, locale = 'es' } = await request.json(); // Default to Spanish
    const origin = request.headers.get('origin') || 'https://antoine.patraldo.com';
    
    // Get translation function
    const t = getTranslation(locale);
    
    if (!email || !isValidEmail(email)) {
      return new Response(
        JSON.stringify({ message: t('subscription.validEmailRequired') }),
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      );
    }
    
    // Check if email already exists (regardless of confirmation status)
    const existingSubscriber = await platform.env.DB.prepare(`
      SELECT * FROM subscribers 
      WHERE email = ? AND type = 'art-updates'
    `).bind(email).first();
    
    // Generate token and expiration
    const token = generateToken();
    const expiresAt = new Date(Date.now() + 24 * 60 * 60 * 1000); // 24 hours
    
    // Handle different subscription states
    if (existingSubscriber) {
      // Case 1: Already confirmed
      if (existingSubscriber.confirmed) {
        return new Response(
          JSON.stringify({ 
            message: t('subscription.alreadyRegistered'),
            status: 'confirmed'
          }),
          { status: 200, headers: { 'Content-Type': 'application/json' } }
        );
      }
      
      // Case 2: Pending confirmation - update token but keep status
      const result = await platform.env.DB.prepare(`
        UPDATE subscribers 
        SET token = ?, token_expires_at = ?, locale = ?
        WHERE email = ? AND type = 'art-updates'
      `).bind(token, expiresAt.toISOString(), locale, email).run();
    } else {
      // Case 3: New subscriber - insert record
      const result = await platform.env.DB.prepare(`
        INSERT INTO subscribers (email, type, token, token_expires_at, confirmed, created_at, locale)
        VALUES (?, 'art-updates', ?, ?, 0, datetime('now'), ?)
      `).bind(email, token, expiresAt.toISOString(), locale).run();
    }
    
    console.log('Subscriber processed:', { 
      email, 
      locale,
      status: existingSubscriber ? (existingSubscriber.confirmed ? 'confirmed' : 'pending') : 'new' 
    });
    
    // Try to send verification email, but don't fail if it doesn't work
    try {
      await sendVerificationEmail(email, platform.env, token, expiresAt, origin, locale, t);
      console.log('Verification email sent successfully');
      
      return new Response(
        JSON.stringify({ 
          message: t('subscription.checkEmail'),
          status: 'pending'
        }),
        { status: 200, headers: { 'Content-Type': 'application/json' } }
      );
    } catch (emailError) {
      console.error('Failed to send verification email:', emailError);
      
      return new Response(
        JSON.stringify({ 
          message: t('subscription.emailFailed'),
          status: 'pending'
        }),
        { status: 500, headers: { 'Content-Type': 'application/json' } }
      );
    }
    
  } catch (error) {
    console.error('Subscription error:', error);
    
    // Fallback to Spanish for errors
    const t = getTranslation('es');
    return new Response(
      JSON.stringify({ message: t('subscription.processingFailed') }),
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    );
  }
}

function isValidEmail(email) {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
}

function generateToken() {
  const array = new Uint8Array(32);
  crypto.getRandomValues(array);
  return Array.from(array, byte => byte.toString(16).padStart(2, '0')).join('');
}

async function sendVerificationEmail(email, env, token, expiresAt, origin, locale, t) {
  const verificationUrl = `${origin}/api/verify?token=${token}&locale=${locale}`;
  
  const htmlContent = `
  <!DOCTYPE html>
  <html>
  <head>
    <meta charset="utf-8">
    <title>${t('email.verificationTitle')}</title>
  </head>
  <body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto; padding: 20px;">
    <div style="border: 1px solid #ddd; border-radius: 5px; padding: 20px;">
      <h2>${t('email.confirmSubscription')}</h2>
      <p>${t('email.thankYou')}</p>
      <p style="text-align: center; margin: 30px 0;">
        <a href="${verificationUrl}" style="display: inline-block; background-color: #667eea; color: #ffffff !important; padding: 12px 24px; text-decoration: none; border-radius: 4px; font-weight: bold;">
          ${t('email.confirmButton')}
        </a>
      </p>
      <p>${t('email.buttonNotWorking')}</p>
      <p style="word-break: break-all;">${verificationUrl}</p>
      <p>${t('email.linkExpires')}</p>
      <div style="margin-top: 30px; font-size: 12px; color: #888;">
        <p>${t('email.copyright')}</p>
        <p>${t('email.ignoreIfNotRequested')}</p>
      </div>
    </div>
  </body>
  </html>
  `;

  await sendEmail(email, t('email.subject'), htmlContent, env);
}

async function sendEmail(to, subject, htmlContent, env) {
  console.log('=== SEND EMAIL DEBUG ===');
  console.log('To:', to);
  console.log('Subject:', subject);
  
  const fromAddress = `Antoine Patraldo <newsletter@patraldo.com>`;
  console.log('FROM Address:', fromAddress);
  console.log('=== END DEBUG ===');

  const maxRetries = 3;
  const retryDelay = 1000;
  
  for (let attempt = 1; attempt <= maxRetries; attempt++) {
    try {
      const controller = new AbortController();
      const timeoutId = setTimeout(() => controller.abort(), 10000);
      
      const fromAddress = `Antoine Patraldo <newsletter@patraldo.com>`;
      
      const response = await fetch(`https://api.mailgun.net/v3/${env.MAILGUN_DOMAIN}/messages`, {
        method: 'POST',
        headers: {
          'Authorization': `Basic ${btoa(`api:${env.MAILGUN_API_KEY}`)}`,
          'Content-Type': 'application/x-www-form-urlencoded'
        },
        body: new URLSearchParams({
          from: fromAddress,
          to: to,
          subject: subject,
          html: htmlContent
        }),
        signal: controller.signal
      });
      
      clearTimeout(timeoutId);
      
      if (!response.ok) {
        const error = await response.text();
        throw new Error(`Mailgun API error: ${error}`);
      }
      
      return await response.json();
    } catch (error) {
      console.error(`Email sending attempt ${attempt} failed:`, error.message);
      
      if (attempt === maxRetries) {
        console.error('All email sending attempts failed');
        throw new Error(`Failed to send email after ${maxRetries} attempts: ${error.message}`);
      }
      
      await new Promise(resolve => setTimeout(resolve, retryDelay));
    }
  }
}
