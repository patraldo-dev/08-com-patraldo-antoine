// src/routes/+page.server.js
import { CF_IMAGES_ACCOUNT_HASH, CUSTOM_DOMAIN } from '$lib/config.js';

export async function load({ platform }) {
  try {
    const db = platform?.env?.ARTWORKS_DB;
    
    if (!db) {
      console.warn('DB not available');
      return { artworks: [] };
    }

    // Query using YOUR actual schema
    const result = await db
      .prepare(`
        SELECT 
          id,
          title,
          slug,
          type,
          image_id,
          video_id,
          description,
          year,
          featured,
          published
        FROM artworks
        WHERE published = 1
        ORDER BY order_index DESC, year DESC
      `)
      .all();

    // Transform to match what the Sketchbook component expects
    const artworks = result.results.map(artwork => {
      // Build Cloudflare Images URL from image_id
      const thumbnailUrl = artwork.image_id 
        ? `https://imagedelivery/${CF_IMAGES_ACCOUNT_HASH}/${artwork.image_id}/thumbnail`
        : null;
      
      return {
        id: artwork.id,
        title: artwork.title,
        description: artwork.description,
        type: artwork.type,
        thumbnailId: artwork.image_id,
        thumbnailUrl: thumbnailUrl,
        videoId: artwork.video_id,
        date: artwork.year ? `${artwork.year}-01-01` : null,
        story: null, // You don't have this column yet
        tags: [] // You don't have this column yet
      };
    });

    console.log(`Loaded ${artworks.length} artworks`);
    return { artworks };
    
  } catch (error) {
    console.error('Error loading artworks:', error);
    return { artworks: [] };
  }
}
