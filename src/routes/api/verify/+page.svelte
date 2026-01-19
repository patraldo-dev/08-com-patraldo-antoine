// src/routes/api/verify/+server.js
import { json, redirect } from '@sveltejs/kit';

export async function GET({ url, platform, cookies }) {
  const { searchParams } = url;
  const token = searchParams.get('token');
  const email = searchParams.get('email');

  if (!token || !email) {
    return json({ error: 'Missing token or email' }, { status: 400 });
  }

  const db = platform.env?.DB_users;
  if (!db) return json({ error: 'DB not connected' }, { status: 500 });

  try {
    // 1. Verify Token
    // (Assuming you have a verification_tokens table or similar logic)
    const { results } = await db.prepare(`
      SELECT user_id FROM email_verifications 
      WHERE token = ? AND used_at IS NULL
    `).bind(token).all();

    if (results.length === 0) {
      return json({ error: 'Invalid or expired token' }, { status: 400 });
    }

    const userId = results[0].user_id;

    // 2. Mark Email as Verified
    await db.prepare(`
      UPDATE users SET is_verified = 1 WHERE id = ?
    `).bind(userId).run();

    // 3. Mark Token as Used
    await db.prepare(`
      UPDATE email_verifications SET used_at = datetime('now') WHERE token = ?
    `).bind(token).run();

    // 4. Log them in (Optional, but good UX)
    // Set their session or redirect them
    // ...

    return json({ success: true });
  } catch (e) {
    return json({ error: e.message }, { status: 500 });
  }
}
