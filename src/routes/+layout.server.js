// src/routes/+layout.server.js
import { redirect } from '@sveltejs/kit';

export async function load({ parent, request, cookies, url }) {
  // Chain to hooks.server.js first (gets user/isAdmin)
  const { user, isAdmin } = await parent();
  
  // --- 1. LANGUAGE LOGIC ---
  let preferredLanguage = cookies.get('preferredLanguage');
  
  if (!preferredLanguage) {
    preferredLanguage = 'es';
    cookies.set('preferredLanguage', preferredLanguage, {
      path: '/',
      httpOnly: true,
      secure: true,
      maxAge: 60 * 60 * 24 * 365,
      sameSite: 'strict',
    });
  }
  
  const validLocales = ['es', 'en', 'fr'];
  if (!validLocales.includes(preferredLanguage)) {
    preferredLanguage = 'es';
  }
  
  // --- 2. ADMIN from HOOKS (already validated) ---
  // Use hooks.server.js result instead of re-checking CF Access
  const finalIsAdmin = isAdmin || false;
  
  return { 
    preferredLanguage, 
    isAdmin: finalIsAdmin,
    user  // Pass full user object from hooks
  };
}

