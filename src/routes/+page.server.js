// src/routes/+page.server.js
import { CF_IMAGES_ACCOUNT_HASH, CUSTOM_DOMAIN } from '$lib/config.js';

export async function load({ platform }) {
  try {
    const db = platform?.env?.ARTWORKS_DB;
    
    if (!db) {
      console.warn('DB not available');
      return { artworks: [] };
    }

    // Query including new story fields
    const result = await db
      .prepare(`
        SELECT 
          id,
          title,
          display_name,
          slug,
          type,
          image_id,
          video_id,
          description,
          year,
          featured,
          published,
          story_enabled,
          story_intro
        FROM artworks
        WHERE published = 1
        ORDER BY order_index DESC, year DESC
      `)
      .all();

    // Transform to match what the Sketchbook component expects
    const artworks = result.results.map(artwork => {
      // Build Cloudflare Images URL from image_id
      const thumbnailUrl = artwork.image_id 
        ? `https://imagedelivery.net/${CF_IMAGES_ACCOUNT_HASH}/${artwork.image_id}/thumbnail`
        : null;
      
      return {
        id: artwork.id,
        title: artwork.title,
        display_name: artwork.display_name,
        description: artwork.description,
        type: artwork.type,
        thumbnailId: artwork.image_id,
        thumbnailUrl: thumbnailUrl,
        videoId: artwork.video_id,
        video_id: artwork.video_id, // Keep both for compatibility
        image_id: artwork.image_id,  // Keep both for compatibility
        date: artwork.year ? `${artwork.year}-01-01` : null,
        year: artwork.year,
        story_enabled: artwork.story_enabled || false,
        story_intro: artwork.story_intro || null,
        tags: [] // Will be populated from story view if needed
      };
    });

    console.log(`Loaded ${artworks.length} artworks (${artworks.filter(a => a.story_enabled).length} with stories)`);
    return { artworks };
    
  } catch (error) {
    console.error('Error loading artworks:', error);
    return { artworks: [] };
  }
}
