-- Drop the existing empty tables
DROP TABLE IF EXISTS artwork_tags;
DROP TABLE IF EXISTS tags;

-- Create tags table with proper structure
CREATE TABLE tags (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL UNIQUE,
  category TEXT NOT NULL, -- 'mood', 'style', 'color', etc.
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create artwork_tags junction table with proper many-to-many structure
CREATE TABLE artwork_tags (
  artwork_id INTEGER NOT NULL,
  tag_id INTEGER NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (artwork_id, tag_id),
  FOREIGN KEY (artwork_id) REFERENCES artworks(id) ON DELETE CASCADE,
  FOREIGN KEY (tag_id) REFERENCES tags(id) ON DELETE CASCADE
);

-- Create indexes for better performance
CREATE INDEX idx_artwork_tags_artwork ON artwork_tags(artwork_id);
CREATE INDEX idx_artwork_tags_tag ON artwork_tags(tag_id);
CREATE INDEX idx_tags_category ON tags(category);

-- Insert mood tags
INSERT INTO tags (name, category) VALUES
  ('melancholic', 'mood'),
  ('vibrant', 'mood'),
  ('surreal', 'mood'),
  ('playful', 'mood'),
  ('contemplative', 'mood'),
  ('energetic', 'mood'),
  ('calm', 'mood'),
  ('mysterious', 'mood');
