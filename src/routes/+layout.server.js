// src/routes/+layout.server.js
import { redirect } from '@sveltejs/kit';

export async function load({ request, cookies, url }) {
  // --- 1. LANGUAGE LOGIC ---
  let preferredLanguage = cookies.get('preferredLanguage');
  
  if (!preferredLanguage) {
    preferredLanguage = 'es';
    cookies.set('preferredLanguage', preferredLanguage, {
      path: '/',
      httpOnly: true,
      secure: true, // Always true for Workers/HTTPS
      maxAge: 60 * 60 * 24 * 365,
      sameSite: 'strict',
    });
  }
  
  const validLocales = ['es', 'en', 'fr'];
  if (!validLocales.includes(preferredLanguage)) {
    preferredLanguage = 'es';
  }
  
  // --- 2. ADMIN LOGIC ---
  let isAdmin = false;
  
  // Use try/catch to prevent URL parsing errors from crashing the whole app
  try {
    // Production
    if (url.hostname === 'antoine.patraldo.com') {
      const cfJwt = request.headers.get('cf-access-jwt-assertion');
      isAdmin = !!cfJwt;
    } 
    // Dev/Preview
    else if (url.hostname === 'localhost' || url.hostname.includes('workers.dev') || url.hostname.includes('pages.dev')) {
      isAdmin = true;
    }
  } catch (e) {
    console.error('Error checking auth:', e);
    isAdmin = false;
  }
  
  return { 
    preferredLanguage, 
    isAdmin 
  };
}
