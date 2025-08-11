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
          return jsonResponse({ message: 'Dirección de correo electrónico no válida' }, 400);
        }
        // Check if already subscribed
        const existingSubscriber = await env.DB.prepare(`
          SELECT confirmed FROM subscribers 
          WHERE email = ? AND type = 'art-updates'
        `).bind(email).first();
        if (existingSubscriber && existingSubscriber.confirmed) {
          return jsonResponse({ message: 'Ya esta registrado, gracias!' }, 200);
        }
        // Send verification email
        await sendVerificationEmail(email, env);
        return jsonResponse({ message: 'Por favor revise su correo electrónico para confirmar su suscripción.' }, 200);
      } catch (error) {
        console.error('Subscription error:', error);
        return jsonResponse({ message: 'No se pudo enviar el correo de verificación. Inténtalo de nuevo.' }, 500);
      }
    }
// Alternative subscription handler:

if (request.method === 'POST' && url.pathname === '/subscribe') {
  try {
    const { email } = await request.json();
    console.log('Subscription request received for email:', email);
    
    if (!email || !isValidEmail(email)) {
      console.log('Invalid email address:', email);
      return jsonResponse({ message: 'Dirección de correo electrónico no válida' }, 400);
    }
    
    // Check if already subscribed
    console.log('Checking if email already exists in database...');
    const existingSubscriber = await env.DB.prepare(`
      SELECT * FROM subscribers 
      WHERE email = ? AND type = 'art-updates'
    `).bind(email).first();
    
    console.log('Existing subscriber check result:', existingSubscriber);
    
    if (existingSubscriber && existingSubscriber.confirmed) {
      console.log('Email already confirmed:', email);
      return jsonResponse({ message: 'Ya está registrado, gracias!' }, 200);
    }
    
    // Generate token and expiration
    const token = generateToken();
    const expiresAt = new Date(Date.now() + 24 * 60 * 60 * 1000); // 24 hours
    console.log('Generated token:', token);
    
    // Check if subscriber exists and update accordingly
    let result;
    if (existingSubscriber) {
      // Update existing subscriber
      console.log('Updating existing subscriber...');
      result = await env.DB.prepare(`
        UPDATE subscribers 
        SET token = ?, token_expires_at = ?, confirmed = 0
        WHERE email = ? AND type = 'art-updates'
      `).bind(token, expiresAt.toISOString(), email).run();
    } else {
      // Insert new subscriber
      console.log('Inserting new subscriber...');
      result = await env.DB.prepare(`
        INSERT INTO subscribers (email, type, token, token_expires_at, confirmed, created_at)
        VALUES (?, 'art-updates', ?, ?, 0, datetime('now'))
      `).bind(email, token, expiresAt.toISOString()).run();
    }
    
    console.log('Database operation result:', result);
    
    // Send verification email (this might fail, but subscriber is already in DB)
    try {
      await sendVerificationEmail(email, env);
      console.log('Verification email sent successfully');
    } catch (emailError) {
      console.error('Failed to send verification email:', emailError);
      // Don't return an error here - the subscriber is already in the database
    }
    
    return jsonResponse({ message: 'Por favor revise su correo electrónico para confirmar su suscripción.' }, 200);
  } catch (error) {
    console.error('Subscription error:', error);
    return jsonResponse({ message: 'No se pudo enviar el correo de verificación. Inténtalo de nuevo.' }, 500);
  }
}
        // Redirect to success page
        return Response.redirect('https://antoine.patraldo.com/subscription-confirmed', 302);
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

  const verificationUrl = `https://antoine.patraldo.com/verify?token=${token}`;
  
  const htmlContent = `
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="utf-8">
      <title>Confirmar su registration</title>
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
        <p>Gracias por registrarse con Antoine Patraldo. Haga click para confirmar su correo electrónico.</p>
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
  // Use the main domain for sending, even though the site is on a subdomain
  const response = await fetch(`https://api.mailgun.net/v3/${env.MAILGUN_DOMAIN}/messages`, {
    method: 'POST',
    headers: {
      'Authorization': `Basic ${btoa(`api:${env.MAILGUN_API_KEY}`)}`,
      'Content-Type': 'application/x-www-form-urlencoded'
    },
    body: new URLSearchParams({
      from: `artoine@patraldo.com`,  // Use main domain, not subdomain
      to: to,
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
