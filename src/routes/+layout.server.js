// src/routes/+layout.server.js
import { redirect } from '@sveltejs/kit';

export async function load({ event, cookies }) {
  // 1. LANGUAGE LOGIC (Keep this, it's fine)
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

  // 2. AUTH LOGIC (Delegated to hooks.server.js)
  // We do not check cookies or headers here.
  // We simply use the 'user' object injected by the hook.
  const user = event.locals.user;
  const isAdmin = user?.role === 'admin';

  return { 
    preferredLanguage, 
    isAdmin,
    username: user?.username
  };
}
