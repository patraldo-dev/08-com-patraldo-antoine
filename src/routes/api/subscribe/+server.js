export async function POST({ request, platform }) {
  try {
    const { email } = await request.json();
    const origin = request.headers.get('origin') || 'https://antoine.patraldo.com';
    
    if (!email || !isValidEmail(email)) {
      return new Response(
        JSON.stringify({ message: 'Valid email is required' }),
        { 
          status: 400, 
          headers: { 'Content-Type': 'application/json' } 
        }
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
            message: 'Ya está registrado, gracias!',
            status: 'confirmed'
          }),
          { status: 200, headers: { 'Content-Type': 'application/json' } }
        );
      }
      
      // Case 2: Pending confirmation - update token but keep status
      const result = await platform.env.DB.prepare(`
        UPDATE subscribers 
        SET token = ?, token_expires_at = ?
        WHERE email = ? AND type = 'art-updates'
      `).bind(token, expiresAt.toISOString(), email).run();
    } else {
      // Case 3: New subscriber - insert record
      const result = await platform.env.DB.prepare(`
        INSERT INTO subscribers (email, type, token, token_expires_at, confirmed, created_at)
        VALUES (?, 'art-updates', ?, ?, 0, datetime('now'))
      `).bind(email, token, expiresAt.toISOString()).run();
    }
    
    console.log('Subscriber processed:', { 
      email, 
      status: existingSubscriber ? (existingSubscriber.confirmed ? 'confirmed' : 'pending') : 'new' 
    });
    
    // Try to send verification email, but don't fail if it doesn't work
    try {
      await sendVerificationEmail(email, platform.env, token, expiresAt, origin);
      console.log('Verification email sent successfully');
      
      return new Response(
        JSON.stringify({ 
          message: 'Por favor revise su correo electrónico para confirmar su suscripción.',
          status: 'pending'
        }),
        { status: 200, headers: { 'Content-Type': 'application/json' } }
      );
    } catch (emailError) {
      console.error('Failed to send verification email:', emailError);
      
      return new Response(
        JSON.stringify({ 
          message: 'Suscripción registrada, pero no pudimos enviar el correo de confirmación.',
          status: 'pending'
        }),
        { status: 500, headers: { 'Content-Type': 'application/json' } }
      );
    }
    
  } catch (error) {
    console.error('Subscription error:', error);
    
    return new Response(
      JSON.stringify({ message: 'No se pudo procesar la suscripción.' }),
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

async function sendVerificationEmail(email, env, token, expiresAt, origin) {
  const baseUrl = origin || env.BASE_URL || 'https://antoine.patraldo.com';
  const verificationUrl = `${baseUrl}/api/verify?token=${token}`;
  
  console.log('Verification URL:', verificationUrl);
  
  const htmlContent = `
  <!DOCTYPE html>
  <html>
  <head>
    <meta charset="utf-8">
    <title>Confirmar suscripción</title>
  </head>
  <body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto; padding: 20px;">
    <div style="border: 1px solid #ddd; border-radius: 5px; padding: 20px;">
      <h2>Confirmar su suscripción</h2>
      <p>Gracias por registrarse con Antoine Patraldo. Haga clic para confirmar su correo electrónico.</p>
      <p style="text-align: center; margin: 30px 0;">
        <a href="${verificationUrl}" style="display: inline-block; background-color: #667eea; color: #ffffff !important; padding: 12px 24px; text-decoration: none; border-radius: 4px; font-weight: bold;">Confirmar correo electrónico</a>
      </p>
      <p>Si el botón no funciona, puede copiar y pegar el siguiente enlace en su navegador:</p>
      <p style="word-break: break-all;">${verificationUrl}</p>
      <p>Este enlace caducará en 24 horas.</p>
      <div style="margin-top: 30px; font-size: 12px; color: #888;">
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
  const maxRetries = 3;
  const retryDelay = 1000;
  
  for (let attempt = 1; attempt <= maxRetries; attempt++) {
    try {
      const controller = new AbortController();
      const timeoutId = setTimeout(() => controller.abort(), 10000);
      
      // FIXED: Using patraldo.com instead of email.patraldo.com
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
