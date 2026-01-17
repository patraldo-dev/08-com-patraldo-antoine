import { redirect } from '@sveltejs/kit';

export async function load({ request, cookies }) {
  // 1. Check the Header (Best for Production Custom Domain)
  const cfJwt = request.headers.get('cf-access-jwt-assertion');
  
  // 2. Check the Cookie (Best for Preview URL and Local Dev)
  // Cloudflare Access sets a cookie named 'CF_Authorization' when you log in.
  const cfCookie = cookies.get('CF_Authorization');

  // If we don't have either, the user is definitely not authenticated
  if (!cfJwt && !cfCookie) {
    // In a real app, you might want to throw a 403 Unauthorized.
    // But to be safe/consistent with your current setup, we redirect home.
    throw redirect(307, '/');
  }

  // If we have one of them, they are good to go.
  return {
    authenticated: true
  };
}
