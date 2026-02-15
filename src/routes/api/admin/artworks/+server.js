// src/routes/api/admin/artworks/+server.js
import { json, error } from '@sveltejs/kit';

export async function POST({ request, platform, locals }) {
  // Use locals from hooks instead of session KV
  if (!locals.user || !locals.isAdmin) {
    throw error(403, 'Forbidden: Admin access required');
  }
  
  const artworksDb = platform?.env?.ARTWORKS_DB;
  const storiesDb = platform?.env?.stories_db;
  
  if (!artworksDb) {
    throw error(500, 'Artworks database not available');
  }
  
  try {
    const artwork = await request.json();
    
    if (!artwork.title || !artwork.image_id) {
      throw error(400, 'Title and Image ID are required');
    }
    
    if (artwork.create_story) {
      if (!artwork.story_title || !artwork.story_slug) {
        throw error(400, 'Story Title and Slug are required when creating a story');
      }
      if (!storiesDb) {
        throw error(500, 'Stories database not available');
      }
    }
    
    const artworkResult = await artworksDb.prepare(`
      INSERT INTO artworks (
        title, display_name, type, image_id, video_id, description, 
        year, featured, published, order_index, story_enabled, story_intro
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    `).bind(
      artwork.title, artwork.display_name, artwork.type, artwork.image_id,
      artwork.video_id, artwork.description, artwork.year, artwork.featured,
      artwork.published, artwork.order_index, artwork.story_enabled, artwork.story_intro
    ).run();
    
    if (!artworkResult.success) {
      throw error(500, 'Failed to insert artwork');
    }
    
    const insertedArtwork = await artworksDb.prepare(`
      SELECT id, title, display_name, image_id 
      FROM artworks 
      WHERE image_id = ? 
      ORDER BY id DESC 
      LIMIT 1
    `).bind(artwork.image_id).first();
    
    let storyId = null;
    
    if (artwork.create_story && storiesDb) {
      const storyResult = await storiesDb.prepare(`
        INSERT INTO stories (title, slug, created_at, updated_at)
        VALUES (?, ?, datetime('now'), datetime('now'))
      `).bind(artwork.story_title, artwork.story_slug).run();

      if (!storyResult.success) {
        throw error(500, 'Artwork saved but failed to create story');
      }

      const insertedStory = await storiesDb.prepare(`
        SELECT id FROM stories WHERE slug = ? ORDER BY id DESC LIMIT 1
      `).bind(artwork.story_slug).first();

      storyId = insertedStory.id;

      await storiesDb.prepare(`
        INSERT INTO story_chapters (story_id, artwork_id, order_index)
        VALUES (?, ?, 1)
      `).bind(storyId, insertedArtwork.id).run();
      
      // Also create initial story content based on the artwork
      if (artwork.story_intro) {
        await artworksDb.prepare(`
          INSERT INTO story_content (artwork_id, content_type, content_text, order_index)
          VALUES (?, ?, ?, 1)
        `).bind(insertedArtwork.id, 'text', artwork.story_intro).run();
      }
    }
    
    return json({
      success: true,
      id: insertedArtwork.id,
      artwork: insertedArtwork,
      storyId: storyId
    });
    
  } catch (err) {
    console.error('Save artwork error:', err);
    throw error(500, err.message || 'Failed to save artwork');
  }
}
