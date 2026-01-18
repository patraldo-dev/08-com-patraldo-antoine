// src/routes/api/auth/logout/+server.js
import { json } from '@sveltejs/kit';

export async function POST({ cookies, platform }) {
  const db = platform?.env?.DB_users;
  const sessionId = cookies.get('session');
  
  // Delete session from database
  if (sessionId && db) {
    await db.prepare('DELETE FROM user_session WHERE id = ?').bind(sessionId).run();
  }
  
  // Clear session cookie
  cookies.delete('session', { path: '/' });
  
  return json({ success: true });
}
