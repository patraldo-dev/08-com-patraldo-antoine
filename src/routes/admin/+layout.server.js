// src/routes/admin/+layout.server.js
//export async function load() {
  // Cloudflare Access handles auth - if request reaches here, user is authenticated
 // return {
  //  authenticated: true
  //};
//}

import { redirect } from '@sveltejs/kit';

export async function load({ request }) {
  // Check for the Cloudflare Access JWT assertion header
  // If this header is missing, it means the request didn't go through CF Access
  // (or someone is bypassing it)
  const cfJwt = request.headers.get('cf-access-jwt-assertion');

  if (!cfJwt) {
    // Log this for security auditing
    console.warn('Unauthorized access attempt to Admin route (Missing CF Access Header)');
    
    // Redirect to home or login, though technically they shouldn't reach here
    // if your CF Access policy is set correctly.
    throw redirect(307, '/');
  }

  // If we get here, Cloudflare Access has validated the user
  return {
    authenticated: true
  };
}
