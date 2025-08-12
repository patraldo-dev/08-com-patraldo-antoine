export async function POST({ request, platform }) {
  try {
    const { email } = await request.json();
    
    if (!email || !isValidEmail(email)) {
      return new Response(
        JSON.stringify({ message: 'Valid email is required' }),
        { 
          status: 400, 
          headers: { 'Content-Type': 'application/json' } 
        }
      );
    }
    
    // Check if already subscribed
    const existingSubscriber = await platform.env.DB.prepare(`
      SELECT * FROM subscribers 
      WHERE email = ? AND type = 'art-updates'
    `).bind(email).first();
    
    if (existingSubscriber && existingSubscriber.confirmed) {
      return new Response(
        JSON.stringify({ message: 'Ya está registrado, gracias!' }),
        { 
          status: 200, 
          headers: { 'Content-Type': 'application/json' } 
        }
      );
    }
    
    // Generate token and expiration
    const token = generateToken();
    const expiresAt = new Date(Date.now() + 24 * 60 * 60 * 1000); // 24 hours
    
    // Check if subscriber exists and update accordingly
    let result;
    if (existingSubscriber) {
      // Update existing subscriber
      result = await platform.env.DB.prepare(`
        UPDATE subscribers 
        SET token = ?, token_expires_at = ?, confirmed = 0
        WHERE email = ? AND type = 'art-updates'
      `).bind(token, expiresAt.toISOString(), email).run();
    } else {
      // Insert new subscriber
      result = await platform.env.DB.prepare(`
        INSERT INTO subscribers (email, type, token, token_expires_at, confirmed, created_at)
        VALUES (?, 'art-updates', ?, ?, 0, datetime('now'))
      `).bind(email, token, expiresAt.toISOString()).run();
    }
    
    // Send verification email (this might fail, but subscriber is already in DB)
    try {
      await sendVerificationEmail(email, platform.env, token, expiresAt);
    } catch (emailError) {
      console.error('Failed to send verification email:', emailError);
      // Don't return an error here - the subscriber is already in the database
    }
    
    return new Response(
      JSON.stringify({ message: 'Por favor revise su correo electrónico para confirmar su suscripción.' }),
      { 
        status: 200, 
        headers: { 'Content-Type': 'application/json' } 
      }
    );
  } catch (error) {
    console.error('Subscription error:', error);
    
    return new Response(
      JSON.stringify({ message: 'No se pudo enviar el correo de verificación. Inténtalo de nuevo.' }),
      { 
        status: 500, 
        headers: { 'Content-Type': 'application/json' } 
      }
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

async function sendVerificationEmail(email, env, token, expiresAt) {
  const verificationUrl = `https://antoine.patraldo.com/verify?token=${token}`;
  
  const htmlContent = `
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="utf-8">
      <title>Confirmar suscripción</title>
      <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto; padding: 20px; }
        .container { border: 1px solid #ddd; border-radius: 5px; padding: 20px; }
        .button { display: inline-block; background: #667eea; color: white; padding: 10px 20px; text-decoration: none; border-radius: 4px; }
        .footer { margin-top: 30px; font-size: 12px; color: #888; }
      </style>
    </head>
    <body>
      <div class="container">
        <h2>Confirmar su suscripción</h2>
        <p>Gracias por registrarse con Antoine Patraldo. Haga clic para confirmar su correo electrónico.</p>
        <p style="text-align: center; margin: 30px 0;">
          <a href="${verificationUrl}" class="button">Confirmar correo electrónico</a>
        </p>
        <p>Si el botón no funciona, puede copiar y pegar el siguiente enlace en su navegador:</p>
        <p>${verificationUrl}</p>
        <p>Este enlace caducará en 24 horas.</p>
        <div class="footer">
          <p>© 2025 Antoine Patraldo. Todos los derechos reservados.</p>
          <p>Si no se suscribió a estas actualizaciones, puede ignorar este correo electrónico.</p>
        </div>
      </div>
    </body>
    </html>
  `;
  
  await sendEmail(email, 'Confirme su suscripción a Antoine Patraldo', htmlContent, env);
}

async function sendEmail(to, subject, htmlContent, env) {
  const response = await fetch(`https://api.mailgun.net/v3/${env.MAILGUN_DOMAIN}/messages`, {
    method: 'POST',
    headers: {
      'Authorization': `Basic ${btoa(`api:${env.MAILGUN_API_KEY}`)}`,
      'Content-Type': 'application/x-www-form-urlencoded'
    },
    body: new URLSearchParams({
      from: `artoine@patraldo.com`,
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
