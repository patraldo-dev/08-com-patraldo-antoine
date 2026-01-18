// src/hooks.server.js
const SESSION_EXPIRES_IN_MS = 30 * 24 * 60 * 60 * 1000; // 30 days

async function validateSession(db, sessionId) {
    const now = Date.now();
    
    const { results } = await db.prepare(`
        SELECT id, user_id, expires_at
        FROM user_session
        WHERE id = ?
    `).bind(sessionId).all();
    
    if (results.length === 0) {
        return null;
    }
    
    const row = results[0];
    const session = {
        id: row.id,
        userId: row.user_id,
        expiresAt: new Date(row.expires_at),
        fresh: false
    };
    
    // Expired?
    if (now >= row.expires_at) {
        await db.prepare('DELETE FROM user_session WHERE id = ?').bind(sessionId).run();
        return null;
    }
    
    // Auto-refresh if past halfway
    if (now >= row.expires_at - (SESSION_EXPIRES_IN_MS / 2)) {
        const newExpiresAt = now + SESSION_EXPIRES_IN_MS;
        await db.prepare(`
            UPDATE user_session
            SET expires_at = ?
            WHERE id = ?
        `).bind(newExpiresAt, sessionId).run();
        
        session.expiresAt = new Date(newExpiresAt);
        session.fresh = true;
    }
    
    return session;
}

function setSessionCookie(cookies, sessionId, expiresAt) {
    cookies.set('session', sessionId, {
        path: '/',
        httpOnly: true,
        secure: true,
        sameSite: 'lax',
        expires: expiresAt
    });
}

function deleteSessionCookie(cookies) {
    cookies.delete('session', { path: '/' });
}

export async function handle({ event, resolve }) {
    // Initialize locals
    event.locals.user = null;
    event.locals.isAdmin = false;
    
    const db = event.platform?.env?.DB_users;
    if (!db) {
        console.error('❌ DB_users binding not found');
        return resolve(event);
    }
    
    // Method 1: Check Cloudflare Access (for /admin routes)
    const cfAccessEmail = event.request.headers.get('cf-access-authenticated-user-email');
    const cfAccessJWT = event.request.headers.get('cf-access-jwt-assertion');
    
    if (cfAccessEmail || cfAccessJWT) {
        let email = cfAccessEmail;
        
        if (!email && cfAccessJWT) {
            try {
                const payload = cfAccessJWT.split('.')[1];
                const decoded = JSON.parse(atob(payload));
                email = decoded.email || decoded.sub;
            } catch (e) {
                console.error('Failed to decode CF JWT:', e);
            }
        }
        
        if (email) {
            // Find or create user from CF Access
            const { results } = await db.prepare(`
                SELECT id, username, email, role
                FROM users
                WHERE email = ?
            `).bind(email).all();
            
            if (results.length > 0) {
                const user = results[0];
                event.locals.user = user;
                event.locals.isAdmin = user.role === 'admin';
                console.log('[Auth] CF Access - User:', user.username, 'Admin:', event.locals.isAdmin);
            }
        }
    }
    
    // Method 2: Check session cookie (for all pages)
    if (!event.locals.user) {
        const sessionId = event.cookies.get('session');
        
        if (sessionId) {
            const session = await validateSession(db, sessionId);
            
            if (session) {
                const { results } = await db.prepare(`
                    SELECT id, username, email, role
                    FROM users
                    WHERE id = ?
                `).bind(session.userId).all();
                
                if (results.length > 0) {
                    const user = results[0];
                    event.locals.user = user;
                    event.locals.isAdmin = user.role === 'admin';
                    event.locals.session = session;
                    
                    console.log('[Auth] Session - User:', user.username, 'Admin:', event.locals.isAdmin);
                } else {
                    // User deleted - invalidate session
                    await db.prepare('DELETE FROM user_session WHERE id = ?').bind(sessionId).run();
                    deleteSessionCookie(event.cookies);
                }
            } else {
                deleteSessionCookie(event.cookies);
            }
        }
    }
    
    const response = await resolve(event);
    
    // Refresh session cookie if needed
    if (event.locals.session?.fresh) {
        setSessionCookie(event.cookies, event.locals.session.id, event.locals.session.expiresAt);
    }
    
    return response;
}
.get(sessionToken, 'json');
        if (session && session.email === email) {
          validSession = true;
          event.locals.user = session;
          event.locals.isAdmin = session.isAdmin || false;
        }
      }
      
      // Create new session if none exists
      if (!validSession && event.platform?.env?.SESSIONS_KV) {
        const newSessionToken = crypto.randomUUID();
        const sessionData = {
          email,
          username: email.split('@')[0],
          isAdmin: true,
          createdAt: Date.now()
        };
        
        await event.platform.env.SESSIONS_KV.put(
          newSessionToken,
          JSON.stringify(sessionData),
          { expirationTtl: 60 * 60 * 24 * 7 } // 7 days
        );
        
        event.cookies.set('session_token', newSessionToken, {
          path: '/',
          httpOnly: true,
          secure: true,
          sameSite: 'lax',
          maxAge: 60 * 60 * 24 * 7
        });
        
        event.locals.user = sessionData;
        event.locals.isAdmin = true;
      }
    }
  }
  
  // Method 2: Check existing session cookie (for all other pages)
  else {
    const sessionToken = event.cookies.get('session_token');
    
    if (sessionToken && event.platform?.env?.SESSIONS_KV) {
      const session = await event.platform.env.SESSIONS_KV.get(sessionToken, 'json');
      
      if (session) {
        event.locals.user = session;
        event.locals.isAdmin = session.isAdmin || false;
      }
    }
  }
  
  return resolve(event);
}
