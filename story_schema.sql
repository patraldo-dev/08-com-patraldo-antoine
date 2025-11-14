-- Migration: Add story support to artworks
-- This allows each artwork to have a rich multi-media story

-- 1. Add story metadata to artworks table
ALTER TABLE artworks ADD COLUMN story_enabled BOOLEAN DEFAULT 0;
ALTER TABLE artworks ADD COLUMN story_intro TEXT; -- Brief intro text for the story

-- 2. Create story_content table for multimedia story elements
CREATE TABLE IF NOT EXISTS story_content (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  artwork_id INTEGER NOT NULL,
  content_type TEXT NOT NULL, -- 'text', 'image', 'video', 'heading'
  content_text TEXT, -- For text/heading content
  media_id TEXT, -- Cloudflare Images ID for images
  video_id TEXT, -- Cloudflare Stream ID for videos
  order_index INTEGER NOT NULL DEFAULT 0, -- Order of appearance in story
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (artwork_id) REFERENCES artworks(id) ON DELETE CASCADE
);

-- 3. Create index for efficient queries
CREATE INDEX idx_story_content_artwork ON story_content(artwork_id, order_index);

-- 4. Optional: Add tags support (if you want tagging)
CREATE TABLE IF NOT EXISTS artwork_tags (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  artwork_id INTEGER NOT NULL,
  tag TEXT NOT NULL,
  FOREIGN KEY (artwork_id) REFERENCES artworks(id) ON DELETE CASCADE
);

CREATE INDEX idx_artwork_tags ON artwork_tags(artwork_id);

-- Example data structure:
-- For an artwork with story_enabled=true, you'd have multiple story_content rows:
-- 
-- artwork_id | content_type | content_text                    | media_id | video_id | order_index
-- -----------|--------------|----------------------------------|----------|----------|------------
-- 1          | heading      | "Chapter 1: The Beginning"       | NULL     | NULL     | 0
-- 1          | text         | "Once upon a time..."            | NULL     | NULL     | 1
-- 1          | image        | NULL                             | cf-id-1  | NULL     | 2
-- 1          | text         | "The journey continued..."       | NULL     | NULL     | 3
-- 1          | video        | NULL                             | NULL     | stream-1 | 4
-- 1          | text         | "And so it ended."               | NULL     | NULL     | 5
