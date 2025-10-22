-- Stories table
CREATE TABLE IF NOT EXISTS stories (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  slug TEXT UNIQUE NOT NULL,          -- e.g., 'monos-bailando'
  title_es TEXT NOT NULL,
  title_en TEXT NOT NULL,
  title_fr TEXT NOT NULL,
  description_es TEXT,
  description_en TEXT,
  description_fr TEXT,
  cover_image_url TEXT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  published BOOLEAN DEFAULT 0,
  order_index INTEGER DEFAULT 0
);

-- Story chapters table
CREATE TABLE IF NOT EXISTS story_chapters (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  story_id INTEGER NOT NULL,
  chapter_number INTEGER NOT NULL,
  slug TEXT NOT NULL,               -- e.g., 'chapter-1'
  title_es TEXT NOT NULL,
  title_en TEXT NOT NULL,
  title_fr TEXT NOT NULL,
  content_es TEXT NOT NULL,
  content_en TEXT NOT NULL,
  content_fr TEXT NOT NULL,
  animation_url TEXT,               -- Cloudflare Stream iframe URL
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  published BOOLEAN DEFAULT 0,
  FOREIGN KEY (story_id) REFERENCES stories(id) ON DELETE CASCADE,
  UNIQUE(story_id, chapter_number)
);

-- Optional: index for performance
CREATE INDEX IF NOT EXISTS idx_stories_slug ON stories(slug);
CREATE INDEX IF NOT EXISTS idx_chapters_story_slug ON story_chapters(story_id, slug);
