import { getTranslation } from '$lib/i18n/server';

export async function GET({ url, platform, request }) {
  try {
    const token = url.searchParams.get('token');
    const locale = url.searchParams.get('locale') || 'es';
    const t = getTranslation(locale);
    
    if (!token) {
      return new Response(t('subscription.invalidToken'), { status: 400 });
    }
    
    const subscriber = await platform.env.DB.prepare(`
      SELECT email, token_expires_at FROM subscribers 
      WHERE token = ? AND type = 'art-updates'
    `).bind(token).first();
    
    if (!subscriber) {
      return new Response(t('subscription.invalidToken'), { status: 400 });
    }
    
    if (new Date(subscriber.token_expires_at) < new Date()) {
      return new Response(t('subscription.tokenExpired'), { status: 400 });
    }
    
    // SIMPLIFIED: No updated_at
    await platform.env.DB.prepare(`
      UPDATE subscribers 
      SET confirmed = 1, token = NULL, token_expires_at = NULL,
          locale = ?
      WHERE email = ? AND type = 'art-updates'
    `).bind(locale, subscriber.email).run();
    
    // Redirect to localized success page
    const origin = request.headers.get('origin') || 'https://antoine.patraldo.com';
    return Response.redirect(`${origin}/${locale}/subscription-confirmed`, 302);
    
  } catch (error) {
    console.error('Verification error:', error);
    const t = getTranslation('es');
    return new Response(t('subscription.verificationFailed'), { status: 500 });
  }
}
