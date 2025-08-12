export async function GET({ url, platform }) {
  try {
    const token = url.searchParams.get('token');
    if (!token) {
      return new Response('Invalid verification token', { status: 400 });
    }
    
    const subscriber = await platform.env.DB.prepare(`
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
    await platform.env.DB.prepare(`
      UPDATE subscribers 
      SET confirmed = 1, token = NULL, token_expires_at = NULL 
      WHERE email = ? AND type = 'art-updates'
    `).bind(subscriber.email).run();
    
    // Redirect to success page
    return Response.redirect('https://antoine.patraldo.com/subscription-confirmed', 302);
  } catch (error) {
    console.error('Verification error:', error);
    return new Response('Verification failed', { status: 500 });
  }
}
