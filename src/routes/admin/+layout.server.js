// src/routes/admin/+layout.server.js
import { redirect } from '@sveltejs/kit';

export async function load({ request, cookies, platform, url }) {
  const host = url.hostname;
  
  let isAuthenticated = false;
  let user = null;

  // PRODUCTION: Require CF Access OR valid admin session
  if (host === 'antoine.patraldo.com') {
    // 1. CF Access (primary)
    const cfJwt = request.headers.get('cf-access-jwt-assertion');
    if (cfJwt) {
      // Already authenticated via CF Access (hooks handles user lookup)
      return { authenticated: true, user: { role: 'admin' } };
    }
    
    // 2. Fallback: DB Session check (YOUR SCHEMA)
    const sessionId = cookies.get('session');  // ← Your cookie name
    if (sessionId && platform?.env?.DB_users) {  // ← Your binding
      const session = await platform.env.DB_users
        .prepare(`
          SELECT s.id, s.user_id, s.expires_at, u.username, u.email, u.role
          FROM user_session s  -- ← Your table name
          JOIN users u ON s.user_id = u.id  -- ← Your join column
          WHERE s.id = ? AND s.expires_at > ?
        `)
        .bind(sessionId, Date.now())
        .first();
        
      if (session && session.role === 'admin') {
        isAuthenticated = true;
        user = {
          username: session.username,
          email: session.email,
          role: session.role
        };
      }
    }
    
    if (!isAuthenticated) {
      throw redirect(307, '/admin/login');
    }
  }

  // DEV MODE: Auto-grant access
  if (host === 'localhost' || host.endsWith('.workers.dev') || host.endsWith('.pages.dev')) {
    isAuthenticated = true;
    user = { username: 'dev_admin', role: 'admin' };
  }

  return { authenticated: isAuthenticated, user };
}

