// src/routes/admin/+layout.server.js
import { error, redirect } from '@sveltejs/kit';

export async function load({ locals }) {  // ✅ Use 'locals' directly
  // We rely ENTIRELY on hooks.server.js
  // If locals.user is missing or not admin, the hook failed or removed them.
  const user = locals.user;  // ✅ Access locals directly
  const isAdmin = user?.role === 'admin';

  if (!user || !isAdmin) {
    throw error(403, 'Forbidden: You do not have access to this area.');
  }

  return {
    authenticated: true,
    username: user.username,
    email: user.email
  };
}
