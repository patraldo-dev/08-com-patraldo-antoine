export function load({ cookies }) {
  const authenticated = cookies.get('authenticated') === 'true';
  
  if (!authenticated) {
    throw redirect(302, '/admin/login');
  }
  
  return {};
}
