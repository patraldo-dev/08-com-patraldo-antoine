// src/routes/collection/+page.server.js
import { CF_IMAGES_ACCOUNT_HASH } from '$lib/config.js';

export async function load({ platform }) {
  try {
    const db = platform?.env?.ARTWORKS_DB;
    
    if (!db) {
      console.warn('DB not available');
      return { allArtworks: [] };
    }

    // Fetch artworks WITH their tags
    const result = await db
      .prepare(`
        SELECT 
          a.id,
          a.title,
          a.display_name,
          a.type,
          a.image_id,
          a.video_id,
          a.description,
          a.year,
          a.story_enabled,
          GROUP_CONCAT(t.name) as tags
        FROM artworks a
        LEFT JOIN artwork_tags at ON a.id = at.artwork_id
        LEFT JOIN tags t ON at.tag_id = t.id
        WHERE a.published = 1
        GROUP BY a.id
        ORDER BY a.year DESC, a.order_index DESC
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
      story_enabled: artwork.story_enabled || false,
      tags: artwork.tags ? artwork.tags.split(',') : [] // Parse tags from CSV to array
    }));

    return { allArtworks };
    
  } catch (error) {
    console.error('Error loading artworks for collection:', error);
    return { allArtworks: [] };
  }
}
