// src/routes/api/auth/signup/+server.js
import { json } from '@sveltejs/kit';
import { hashPassword } from '$lib/auth-helpers.js';

export async function POST({ request, platform }) {
    const db = platform?.env?.DB_users;
    if (!db) return json({ error: 'DB unavailable' }, { status: 500 });
    
    const { username, email, password } = await request.json();
    
    if (!username || !email || !password) {
        return json({ error: 'All fields required' }, { status: 400 });
    }
    
    // Check if user exists
    const { results: existing } = await db.prepare(`
        SELECT id FROM users WHERE username = ? OR email = ?
    `).bind(username, email).all();
    
    if (existing.length > 0) {
        return json({ error: 'Username or email already taken' }, { status: 409 });
    }
    
    // Hash password and create user
    const passwordHash = await hashPassword(password);
    const userId = crypto.randomUUID();
    const emailVerificationToken = crypto.randomUUID();
    const now = Date.now();
    
    await db.prepare(`
        INSERT INTO users (id, username, email, hashed_password, role, email_verification_token, created_at, updated_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    `).bind(userId, username, email, passwordHash, 'user', emailVerificationToken, now, now).run();
    
    // TODO: Send verification email using Mailgun
    // For now, we'll auto-verify for simplicity
    // Uncomment when Mailgun is set up:
    /*
    try {
        const confirmUrl = `https://antoine.patraldo.com/confirm?token=${encodeURIComponent(emailVerificationToken)}`;
        await sendMailgunEmail({
            to: email,
            subject: 'Verify Your Email - Antoine Patraldo',
            html: `
                <h2>Welcome!</h2>
                <p>Click the link below to verify your email:</p>
                <a href="${confirmUrl}">Verify Email</a>
            `
        }, {
            MAILGUN_API_KEY: platform.env.MAILGUN_API_KEY,
            MAILGUN_DOMAIN: platform.env.MAILGUN_DOMAIN
        });
    } catch (err) {
        console.error('Failed to send verification email:', err);
    }
    */
    
    return json({ success: true });
}
