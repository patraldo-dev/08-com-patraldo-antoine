import { redirect } from '@sveltejs/kit';

export async function load({ request }) {
  // Check the Hostname
  const url = new URL(request.url);
  const host = url.hostname;

  // STRICT SECURITY FOR PRODUCTION
  // Only enforce Cloudflare Access if we are on the live domain
  if (host === 'antoine.patraldo.com') {
    const cfJwt = request.headers.get('cf-access-jwt-assertion');
    
    if (!cfJwt) {
      console.warn('Unauthorized access attempt on Production');
      throw redirect(307, '/');
    }
  }

  // DEVELOPMENT / PREVIEW MODE
  // If we are on localhost or *.workers.dev, we allow access directly
  // This allows you to use the Git Preview URLs without logging in
  if (host === 'localhost' || host.endsWith('.workers.dev')) {
    console.log(`Admin access granted for Preview/Dev: ${host}`);
  }

  return {
    authenticated: true
  };
}
