-- User sessions table for authentication
-- Sessions stored in D1, cookie contains only the session token
-- Sessions auto-refresh at 50% lifetime (30-day total expiry)

CREATE TABLE IF NOT EXISTS user_session (
  id TEXT PRIMARY KEY,                          -- UUID v4 (session token)
  user_id TEXT NOT NULL,                        -- References users.id
  expires_at INTEGER NOT NULL,                  -- Unix timestamp (ms) when session expires
  created_at INTEGER NOT NULL,                  -- Unix timestamp (ms) when session was created
  
  -- Foreign key constraint (optional - D1 doesn't enforce FK by default)
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Indexes for common queries
CREATE INDEX IF NOT EXISTS idx_session_user ON user_session(user_id);
CREATE INDEX IF NOT EXISTS idx_session_expires ON user_session(expires_at);

-- Trigger to auto-update user.updated_at when user row changes
CREATE TRIGGER IF NOT EXISTS update_users_updated_at 
AFTER UPDATE ON users
BEGIN
  UPDATE users SET updated_at = (strftime('%s', 'now') * 1000) WHERE id = NEW.id;
END;
