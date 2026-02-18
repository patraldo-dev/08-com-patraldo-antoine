-- Users table for authentication
-- Used by custom session-based auth system (not Lucia)
-- Passwords hashed with PBKDF2 (100k iterations, SHA-256)

CREATE TABLE IF NOT EXISTS users (
  id TEXT PRIMARY KEY,                          -- UUID v4
  username TEXT NOT NULL UNIQUE,                -- Unique username (3-32 chars)
  email TEXT NOT NULL UNIQUE,                   -- User's email address
  hashed_password TEXT NOT NULL,                -- Format: "iterations:saltB64:hashB64"
  role TEXT NOT NULL DEFAULT 'user',            -- 'user' or 'admin'
  
  -- Email verification
  email_verification_token TEXT,                -- Token for email verification (NULL after verified)
  email_verified_at INTEGER,                    -- Unix timestamp when email was verified (NULL if not verified)
  
  -- Timestamps
  created_at INTEGER NOT NULL,                  -- Unix timestamp (ms)
  updated_at INTEGER NOT NULL                   -- Unix timestamp (ms)
);

-- Indexes for common queries
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_username ON users(username);
CREATE INDEX IF NOT EXISTS idx_users_role ON users(role);
CREATE INDEX IF NOT EXISTS idx_users_email_token ON users(email_verification_token);
