// src/routes/+layout.server.js
import { redirect } from '@sveltejs/kit';

/** @type {import('./$types').LayoutServerLoad} */
export async function load({ request, cookies }) {
  // --- 1. EXISTING LANGUAGE LOGIC (Unchanged) ---
  
  // Get language from cookie
  let preferredLanguage = cookies.get('preferredLanguage');

  // If no cookie exists, set it to default (es) and send it back
  if (!preferredLanguage) {
    preferredLanguage = 'es';
    // Set the cookie for future requests
    // Max-Age is in seconds. This sets it for about 1 year.
    cookies.set('preferredLanguage', preferredLanguage, {
      path: '/',
      httpOnly: true, // Recommended for security
      secure: process.env.NODE_ENV === 'production', // Only send over HTTPS in production
      maxAge: 60 * 60 * 24 * 365, // 1 year
      sameSite: 'strict', // Recommended for security
    });
  }

  // Validate the language (good practice)
  const validLocales = ['es', 'en', 'fr'];
  if (!validLocales.includes(preferredLanguage)) {
    preferredLanguage = 'es'; // Fallback if cookie value is invalid
  }

  // --- 2. NEW ADMIN LOGIC (Added) ---
  
  const url = new URL(request.url);
  let isAdmin = false;

  // Check if we are on Production
  if (url.hostname === 'antoine.patraldo.com') {
    // Check for Cloudflare Access JWT header
    const cfJwt = request.headers.get('cf-access-jwt-assertion');
    isAdmin = !!cfJwt;
  } 
  // Check if we are in Development or Preview
  else if (url.hostname === 'localhost' || url.hostname.endsWith('.workers.dev')) {
    isAdmin = true; 
  }

  // --- 3. RETURN DATA ---
  
  // Return both language AND admin status
  return { 
    preferredLanguage, 
    isAdmin 
  };
}
