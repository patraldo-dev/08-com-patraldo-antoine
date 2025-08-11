// Artist Portfolio Email Worker
export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);
    
    // Handle CORS
    if (request.method === 'OPTIONS') {
      return new Response(null, {
        headers: {
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Methods': 'POST, GET, OPTIONS',
          'Access-Control-Allow-Headers': 'Content-Type'
        }
      });
    }
    // Handle email subscription
    if (request.method === 'POST' && url.pathname === '/subscribe') {
      try {
        const { email } = await request.json();
        if (!email || !isValidEmail(email)) {
          return jsonResponse({ message: 'Invalid email address' }, 400);
        }
        // Check if already subscribed
        const existingSubscriber = await env.DB.prepare(`
          SELECT confirmed FROM subscribers 
          WHERE email = ? AND type = 'art-updates'
        `).bind(email).first();
        if (existingSubscriber && existingSubscriber.confirmed) {
          return jsonResponse({ message: 'You\'re already subscribed!' }, 200);
        }
        // Send verification email
        await sendVerificationEmail(email, env);
        return jsonResponse({ message: 'Please check your email to confirm your subscription!' }, 200);
      } catch (error) {
        console.error('Subscription error:', error);
        return jsonResponse({ message: 'Failed to send verification email. Please try again.' }, 500);
      }
    }
    // Handle email verification
    if (request.method === 'GET' && url.pathname === '/verify') {
      try {
        const token = url.searchParams.get('token');
        if (!token) {
          return new Response('Invalid verification token', { status: 400 });
        }
        const subscriber = await env.DB.prepare(`
          SELECT email, token_expires_at FROM subscribers 
          WHERE token = ? AND type = 'art-updates'
        `).bind(token).first();

        if (!subscriber) {
          return new Response('Invalid verification token', { status: 400 });
        }

        if (new Date(subscriber.token_expires_at) < new Date()) {
          return new Response('Verification token expired', { status: 400 });
        }

        // Update subscriber as confirmed
        await env.DB.prepare(`
          UPDATE subscribers 
          SET confirmed = 1, token = NULL, token_expires_at = NULL 
          WHERE email = ? AND type = 'art-updates'
        `).bind(subscriber.email).run();

        // Redirect to success page
        return Response.redirect('https://your-domain.com/subscription-confirmed', 302);
      } catch (error) {
        console.error('Verification error:', error);
        return new Response('Verification failed', { status: 500 });
      }
    }

    // Handle sending announcements
    if (request.method === 'POST' && url.pathname === '/send-announcement') {
      try {
        // Basic auth check - replace with proper auth in production
        const authHeader = request.headers.get('Authorization');
        if (authHeader !== `Bearer ${env.AUTH_TOKEN}`) {
          return jsonResponse({ message: 'Unauthorized' }, 401);
        }

        const { subject, content } = await request.json();
        if (!subject || !content) {
          return jsonResponse({ message: 'Subject and content are required' }, 400);
        }

        // Get all confirmed subscribers
        const subscribers = await env.DB.prepare(`
          SELECT email FROM subscribers 
          WHERE confirmed = 1 AND type = 'art-updates'
        `).all();

        if (subscribers.results.length === 0) {
          return jsonResponse({ message: 'No subscribers found' }, 200);
        }

        // Send email to each subscriber
        for (const subscriber of subscribers.results) {
          await sendEmail(subscriber.email, subject, content, env);
        }

        return jsonResponse({ 
          message: `Announcement sent to ${subscribers.results.length} subscribers` 
        }, 200);
      } catch (error) {
        console.error('Announcement error:', error);
        return jsonResponse({ message: 'Failed to send announcement' }, 500);
      }
    }

    return new Response('Not found', { status: 404 });
  }
};

// Helper functions
function jsonResponse(data, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: {
      'Content-Type': 'application/json',
      'Access-Control-Allow-Origin': '*'
    }
  });
}

function isValidEmail(email) {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
}

async function sendVerificationEmail(email, env) {
  const token = generateToken();
  const expiresAt = new Date(Date.now() + 24 * 60 * 60 * 1000); // 24 hours
  
  // Store subscriber with token
  await env.DB.prepare(`
    INSERT OR REPLACE INTO subscribers (email, type, token, token_expires_at, confirmed)
    VALUES (?, 'art-updates', ?, ?, 0)
  `).bind(email, token, expiresAt.toISOString()).run();

  const verificationUrl = `https://your-worker.your-subdomain.workers.dev/verify?token=${token}`;
  
  const htmlContent = `
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="utf-8">
      <title>Verify your subscription</title>
      <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto; padding: 20px; }
        .container { border: 1px solid #ddd; border-radius: 5px; padding: 20px; }
        .button { display: inline-block; background: #667eea; color: white; padding: 10px 20px; text-decoration: none; border-radius: 4px; }
        .footer { margin-top: 30px; font-size: 12px; color: #888; }
      </style>
    </head>
    <body>
      <div class="container">
        <h2>Verify Your Subscription</h2>
        <p>Thank you for subscribing to Antoine Patraldo's art updates! Please click the button below to verify your email address:</p>
        <p style="text-align: center; margin: 30px 0;">
          <a href="${verificationUrl}" class="button">Verify Email</a>
        </p>
        <p>If the button doesn't work, you can copy and paste the following link into your browser:</p>
        <p>${verificationUrl}</p>
        <p>This link will expire in 24 hours.</p>
        <div class="footer">
          <p>© 2025 Antoine Patraldo. All rights reserved.</p>
          <p>If you didn't subscribe to these updates, you can ignore this email.</p>
        </div>
      </div>
    </body>
    </html>
  `;

  await sendEmail(email, 'Verify Your Subscription to Antoine Patraldo Art Updates', htmlContent, env);
}

async function sendEmail(to, subject, htmlContent, env) {
  // Using Resend for email delivery - update with your preferred service
  const response = await fetch('https://api.resend.com/emails', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${env.RESEND_API_KEY}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      from: 'art@mayachen.com',
      to: [to],
      subject: subject,
      html: htmlContent
    })
  });

  if (!response.ok) {
    const error = await response.text();
    throw new Error(`Email sending failed: ${error}`);
  }

  return await response.json();
}

function generateToken() {
  const array = new Uint8Array(32);
  crypto.getRandomValues(array);
  return Array.from(array, byte => byte.toString(16).padStart(2, '0')).join('');
}
