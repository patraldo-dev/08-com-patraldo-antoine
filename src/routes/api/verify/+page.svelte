<!-- src/routes/api/verify/+page.svelte -->
<script>
  import { error, redirect } from '@sveltejs/kit';

  export async function GET({ url, platform, cookies }) {
    const searchParams = url.searchParams;
    const token = searchParams.get('token');
    const email = searchParams.get('email');

    if (!token || !email) {
      return new Response(
        JSON.stringify({ error: 'Missing token or email' }),
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      );
    }

    const db = platform?.env?.DB_users;
    if (!db) {
      return new Response(
        JSON.stringify({ error: 'Database connection unavailable' }),
        { status: 500, headers: { 'Content-Type': 'application/json' } }
      );
    }

    try {
      // 1. Verify Token
      const { results } = await db.prepare(`
        SELECT user_id FROM email_verifications
        WHERE token = ? AND used_at IS NULL
      `).bind(token).all();

      if (results.length === 0) {
        return new Response(
          JSON.stringify({ error: 'Invalid or expired token' }),
          { status: 400, headers: { 'Content-Type': 'application/json' } }
        );
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
      // You can create a session here or just let them know they are verified
      // console.log(`User ${userId} verified via email`);

      // 5. Redirect to a success page or stories
      throw redirect(303, '/stories'); // or wherever you want them to go

    } catch (e) {
      console.error('Verification error:', e);
      return new Response(
        JSON.stringify({ error: 'Verification failed' }),
        { status: 500, headers: { 'Content-Type': 'application/json' } }
      );
    }
  }
</script>
