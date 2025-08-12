CREATE TABLE IF NOT EXISTS artworks (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT NOT NULL,
  type TEXT NOT NULL CHECK (type IN ('still', 'animation', 'gif')),
  image_id TEXT NOT NULL,
  video_id TEXT,
  description TEXT NOT NULL,
  year INTEGER NOT NULL,
  featured BOOLEAN DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_artworks_type ON artworks(type);
CREATE INDEX IF NOT EXISTS idx_artworks_year ON artworks(year);
