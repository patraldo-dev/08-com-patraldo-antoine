export async function POST({ request, platform }) {
  try {
    const { email = 'test@example.com' } = await request.json();
    
    if (!platform?.env?.MAILGUN_API_KEY) {
      return new Response(JSON.stringify({
        error: 'Mailgun environment variables not configured'
      }), { status: 500 });
    }
    
    // Test send a simple email
    const testHtml = `
      <h2>Test Email</h2>
      <p>This is a test email from ${request.headers.get('origin') || 'unknown origin'}</p>
      <p>Timestamp: ${new Date().toISOString()}</p>
    `;
    
    const response = await fetch(`https://api.mailgun.net/v3/${platform.env.MAILGUN_DOMAIN}/messages`, {
      method: 'POST',
      headers: {
        'Authorization': `Basic ${btoa(`api:${platform.env.MAILGUN_API_KEY}`)}`,
        'Content-Type': 'application/x-www-form-urlencoded'
      },
      body: new URLSearchParams({
        from: 'Antoine Patraldo <newsletter@patraldo.com>',
        to: email,
        subject: 'Test Email from Antoine Patraldo',
        html: testHtml
      })
    });
    
    if (!response.ok) {
      const error = await response.text();
      throw new Error(`Mailgun error: ${error}`);
    }
    
    const result = await response.json();
    
    return new Response(JSON.stringify({
      success: true,
      message: 'Test email sent',
      mailgunResponse: result,
      fromDomain: 'patraldo.com',
      to: email,
      timestamp: new Date().toISOString()
    }, null, 2), {
      headers: { 'Content-Type': 'application/json' }
    });
    
  } catch (error) {
    return new Response(JSON.stringify({
      error: error.message,
      timestamp: new Date().toISOString()
    }, null, 2), {
      status: 500,
      headers: { 'Content-Type': 'application/json' }
    });
  }
}

export async function GET() {
  return new Response(JSON.stringify({
    message: 'Send POST request with { "email": "your@email.com" } to test email sending',
    endpoints: {
      test: 'POST /api/test-email',
      subscribe: 'POST /api/subscribe',
      verify: 'GET /api/verify?token=XXX'
    }
  }, null, 2), {
    headers: { 'Content-Type': 'application/json' }
  });
}
