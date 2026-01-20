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
    
    // Send verification email using Mailgun
    try {
        const confirmUrl = `https://antoine.patraldo.com/auth/verify-email?token=${encodeURIComponent(emailVerificationToken)}`;
        
        const mailgunDomain = platform.env.MAILGUN_DOMAIN || 'patraldo.com';
        const mailgunApiKey = platform.env.MAILGUN_API_KEY;
        
        if (mailgunApiKey) {
            const formData = new FormData();
            formData.append('from', `Antoine Patraldo <noreply@${mailgunDomain}>`);
            formData.append('to', email);
            formData.append('subject', 'Verify Your Email - Antoine Patraldo');
            formData.append('html', `
                <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
                    <h2 style="color: #2c5e3d;">Welcome to Antoine Patraldo!</h2>
                    <p>Thank you for creating an account. Please verify your email address by clicking the button below:</p>
                    <div style="text-align: center; margin: 30px 0;">
                        <a href="${confirmUrl}" style="display: inline-block; padding: 12px 30px; background: #2c5e3d; color: white; text-decoration: none; border-radius: 6px;">Verify Email</a>
                    </div>
                    <p style="color: #666; font-size: 14px;">Or copy and paste this link into your browser:</p>
                    <p style="color: #2c5e3d; word-break: break-all;">${confirmUrl}</p>
                    <p style="color: #999; font-size: 12px; margin-top: 30px;">If you didn't create this account, you can safely ignore this email.</p>
                </div>
            `);
            
            const response = await fetch(`https://api.mailgun.net/v3/${mailgunDomain}/messages`, {
                method: 'POST',
                headers: {
                    'Authorization': `Basic ${btoa(`api:${mailgunApiKey}`)}`
                },
                body: formData
            });
            
            if (!response.ok) {
                const errorText = await response.text();
                console.error('Mailgun error:', errorText);
            } else {
                console.log('Verification email sent successfully to:', email);
            }
        } else {
            console.warn('Mailgun API key not configured - email not sent');
        }
    } catch (err) {
        console.error('Failed to send verification email:', err);
        // Don't fail signup if email fails
    }
    
    return json({ success: true });
}
