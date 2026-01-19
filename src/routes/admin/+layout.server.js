// src/routes/admin/+layout.server.js
import { error, redirect } from '@sveltejs/kit';

export async function load({ event }) {
  // We rely ENTIRELY on hooks.server.js
  // If event.locals.user is missing or not admin, the hook failed or removed them.
  const user = event.locals.user;
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
