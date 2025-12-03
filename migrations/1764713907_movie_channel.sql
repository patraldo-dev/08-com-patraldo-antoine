-- Movie Channel Feature with i18n support

CREATE TABLE IF NOT EXISTS films (
  id TEXT PRIMARY KEY,
  title_es TEXT NOT NULL,
  title_en TEXT,
  title_fr TEXT,
  description_es TEXT,
  description_en TEXT,
  description_fr TEXT,
  stream_video_id TEXT NOT NULL,
  thumbnail_url TEXT,
  duration INTEGER,
  is_featured INTEGER DEFAULT 0,
  created_at INTEGER NOT NULL,
  view_count INTEGER DEFAULT 0
);

CREATE TABLE IF NOT EXISTS watch_history (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  film_id TEXT NOT NULL,
  watched_at INTEGER NOT NULL,
  progress INTEGER DEFAULT 0,
  FOREIGN KEY (film_id) REFERENCES films(id)
);

CREATE INDEX idx_watch_history_user ON watch_history(user_id);
CREATE INDEX idx_watch_history_film ON watch_history(film_id);
CREATE INDEX idx_films_featured ON films(is_featured);
