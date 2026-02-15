-- Migration to add missing columns to artworks table
-- These columns are expected by the admin artwork upload page

-- Add display_name column
ALTER TABLE artworks ADD COLUMN display_name TEXT;

-- Add video_id column
ALTER TABLE artworks ADD COLUMN video_id TEXT;

-- Add published column (if not already added)
-- ALTER TABLE artworks ADD COLUMN published BOOLEAN DEFAULT 1;

-- Add order_index column (if not already added)
-- ALTER TABLE artworks ADD COLUMN order_index INTEGER DEFAULT 999;

-- Add story_intro column (if not already added in story_schema.sql)
-- ALTER TABLE artworks ADD COLUMN story_intro TEXT;

-- Add story_enabled column (if not already added in story_schema.sql)
-- ALTER TABLE artworks ADD COLUMN story_enabled BOOLEAN DEFAULT 0;

-- Update existing records to have display_name equal to title if not set
UPDATE artworks SET display_name = title WHERE display_name IS NULL OR display_name = '';

-- Update existing records to have published = 1 if not set
UPDATE artworks SET published = 1 WHERE published IS NULL;

-- Update existing records to have order_index = 999 if not set
UPDATE artworks SET order_index = 999 WHERE order_index IS NULL;