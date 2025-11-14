-- Simple Story Setup
-- This creates a basic text-only story for your FIRST artwork

-- First, enable story for the first published artwork
UPDATE artworks 
SET 
  story_enabled = 1,
  story_intro = 'Behind every artwork is a story. Here is mine...'
WHERE id = (SELECT id FROM artworks WHERE published = 1 ORDER BY order_index ASC LIMIT 1);

-- Add a simple text-only story
-- Using a variable to get the first artwork ID
INSERT INTO story_content (artwork_id, content_type, content_text, order_index)
SELECT 
  id,
  'heading',
  'The Beginning',
  0
FROM artworks 
WHERE published = 1 
ORDER BY order_index ASC 
LIMIT 1;

INSERT INTO story_content (artwork_id, content_type, content_text, order_index)
SELECT 
  id,
  'text',
  'This piece began as a simple sketch during a quiet morning. I was inspired by the way light filtered through my studio window, creating patterns on the floor that seemed to dance and shift with every passing cloud.',
  1
FROM artworks 
WHERE published = 1 
ORDER BY order_index ASC 
LIMIT 1;

INSERT INTO story_content (artwork_id, content_type, content_text, order_index)
SELECT 
  id,
  'heading',
  'The Process',
  2
FROM artworks 
WHERE published = 1 
ORDER BY order_index ASC 
LIMIT 1;

INSERT INTO story_content (artwork_id, content_type, content_text, order_index)
SELECT 
  id,
  'text',
  'Working on this artwork taught me patience. Each layer required time to dry, time to reflect, time to understand what the piece was trying to become. Art has its own voice, and sometimes the best thing an artist can do is listen.',
  3
FROM artworks 
WHERE published = 1 
ORDER BY order_index ASC 
LIMIT 1;

INSERT INTO story_content (artwork_id, content_type, content_text, order_index)
SELECT 
  id,
  'heading',
  'The Final Result',
  4
FROM artworks 
WHERE published = 1 
ORDER BY order_index ASC 
LIMIT 1;

INSERT INTO story_content (artwork_id, content_type, content_text, order_index)
SELECT 
  id,
  'text',
  'What you see before you is the culmination of weeks of experimentation, discovery, and growth. Every mark tells part of the story, every color choice reflects a decision made in that moment of creation.',
  5
FROM artworks 
WHERE published = 1 
ORDER BY order_index ASC 
LIMIT 1;

-- Verify it worked
SELECT 'Story content created:' as info;
SELECT a.title, sc.content_type, sc.order_index 
FROM story_content sc
JOIN artworks a ON a.id = sc.artwork_id
ORDER BY sc.artwork_id, sc.order_index;
