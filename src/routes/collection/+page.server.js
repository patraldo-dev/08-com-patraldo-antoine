// src/routes/collection/+page.server.js
import { CF_IMAGES_ACCOUNT_HASH } from '$lib/config.js';

export async function load({ platform }) {
  try {
    const db = platform?.env?.ARTWORKS_DB;
    
    if (!db) {
      console.warn('DB not available');
      return { allArtworks: [] };
    }

    // Fetch ALL artworks (we'll filter on client side based on visits)
    const result = await db
      .prepare(`
        SELECT 
          id,
          title,
          display_name,
          type,
          image_id,
          video_id,
          description,
          year,
          story_enabled
        FROM artworks
        WHERE published = 1
        ORDER BY year DESC, order_index DESC
      `)
      .all();

    const allArtworks = result.results.map(artwork => ({
      id: artwork.id,
      title: artwork.title,
      display_name: artwork.display_name,
      type: artwork.type,
      thumbnailId: artwork.image_id,
      thumbnailUrl: artwork.image_id 
        ? `https://imagedelivery.net/${CF_IMAGES_ACCOUNT_HASH}/${artwork.image_id}/thumbnail`
        : null,
      videoId: artwork.video_id,
      description: artwork.description,
      year: artwork.year,
      story_enabled: artwork.story_enabled || false
    }));

    return { allArtworks };
    
  } catch (error) {
    console.error('Error loading artworks for collection:', error);
    return { allArtworks: [] };
  }
}
