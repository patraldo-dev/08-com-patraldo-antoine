// src/routes/+layout.server.js
import { redirect } from '@sveltejs/kit'; // Import redirect if needed elsewhere

/** @type {import('./$types').LayoutServerLoad} */
export async function load({ request, cookies }) {
  // Get language from cookie
  let preferredLanguage = cookies.get('preferredLanguage');

  // If no cookie exists, set it to the default (es-MX) and send it back
  if (!preferredLanguage) {
    preferredLanguage = 'es-MX';
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
  const validLocales = ['es-MX', 'en-US', 'fr-CA'];
  if (!validLocales.includes(preferredLanguage)) {
    preferredLanguage = 'es-MX'; // Fallback if cookie value is invalid
  }

  return { preferredLanguage };
}
