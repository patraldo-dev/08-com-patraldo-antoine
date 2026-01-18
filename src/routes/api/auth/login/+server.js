// src/routes/api/auth/login/+server.js
import { json } from '@sveltejs/kit';
import { verifyPassword, generateSessionToken } from '$lib/auth-helpers.js';

export async function POST({ request, platform, cookies }) {
    const db = platform?.env?.DB_users;
    if (!db) return json({ error: 'DB unavailable' }, { status: 500 });
    
    const { identifier, password } = await request.json();
    
    if (!identifier || !password) {
        return json({ error: 'Email/username and password required' }, { status: 400 });
    }
    
    // Find user by email OR username
    const { results } = await db.prepare(`
        SELECT id, username, email, hashed_password, role, email_verified_at
        FROM users
        WHERE email = ? OR username = ?
        LIMIT 1
    `).bind(identifier, identifier).all();
    
    if (results.length === 0) {
        return json({ error: 'Invalid credentials' }, { status: 401 });
    }
    
    const user = results[0];
    
    // Verify password
    const isValid = await verifyPassword(password, user.hashed_password);
    if (!isValid) {
        return json({ error: 'Invalid credentials' }, { status: 401 });
    }
    
    // Check if email verified (optional - remove if you want to allow unverified login)
    if (!user.email_verified_at) {
        return json({ error: 'Please verify your email first' }, { status: 403 });
    }
    
    // Create session
    const sessionId = generateSessionToken();
    const expiresAt = Date.now() + (30 * 24 * 60 * 60 * 1000); // 30 days
    
    await db.prepare(`
        INSERT INTO user_session (id, user_id, expires_at, created_at)
        VALUES (?, ?, ?, ?)
    `).bind(sessionId, user.id, expiresAt, Date.now()).run();
    
    // Set HttpOnly cookie
    cookies.set('session', sessionId, {
        path: '/',
        httpOnly: true,
        secure: true,
        sameSite: 'lax',
        maxAge: 30 * 24 * 60 * 60 // 30 days
    });
    
    return json({ 
        success: true, 
        user: { 
            id: user.id, 
            username: user.username, 
            email: user.email,
            role: user.role
        } 
    });
}
