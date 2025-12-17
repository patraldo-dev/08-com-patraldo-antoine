// src/routes/admin/+layout.server.js
export async function load() {
  // Cloudflare Access handles auth - if request reaches here, user is authenticated
  return {
    authenticated: true
  };
}
