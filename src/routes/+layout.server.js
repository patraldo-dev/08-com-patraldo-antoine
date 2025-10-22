// src/routes/+layout.server.js
/** @type {import('./$types').LayoutServerLoad} */
export async function load({ request }) {
  // Get language from cookie or default to es-MX
  const cookies = request.headers.get('cookie') || '';
  const preferredLanguage = cookies.match(/preferredLanguage=([^;]+)/)?.[1] || 'es-MX';
  
  return { preferredLanguage };
}
