// src/routes/auth/verify-email/+server.js
export async function GET({ url, platform }) {
    try {
        const token = url.searchParams.get('token');
        
        if (!token) {
            return new Response('Invalid verification token', { status: 400 });
        }
        
        const db = platform?.env?.DB_users;
        if (!db) {
            return new Response('Database unavailable', { status: 500 });
        }
        
        // Find user with this verification token
        const { results } = await db.prepare(`
            SELECT id, email, email_verified_at
            FROM users
            WHERE email_verification_token = ?
        `).bind(token).all();
        
        if (results.length === 0) {
            return new Response('Invalid or expired verification token', { status: 400 });
        }
        
        const user = results[0];
        
        // Check if already verified
        if (user.email_verified_at) {
            return Response.redirect('https://antoine.patraldo.com/login?verified=already', 302);
        }
        
        // Mark email as verified
        const now = Date.now();
        await db.prepare(`
            UPDATE users
            SET email_verified_at = ?, email_verification_token = NULL, updated_at = ?
            WHERE id = ?
        `).bind(now, now, user.id).run();
        
        console.log('Email verified for:', user.email);
        
        // Redirect to login page with success message
        return Response.redirect('https://antoine.patraldo.com/login?verified=success', 302);
        
    } catch (error) {
        console.error('Email verification error:', error);
        return new Response('Verification failed', { status: 500 });
    }
}
