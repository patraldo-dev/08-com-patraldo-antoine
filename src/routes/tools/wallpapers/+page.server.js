// src/routes/tools/wallpapers/+page.server.js
import { CF_IMAGES_ACCOUNT_HASH } from '$lib/config.js';

/** @type {import('./$types').PageServerLoad} */
export async function load({ platform }) {
  try {
    const db = platform?.env?.ARTWORKS_DB;

    if (!db) {
      console.warn('DB not available');
      return { artworks: [], cfImagesHash: CF_IMAGES_ACCOUNT_HASH };
    }

    // Fetch artworks suitable for wallpapers
    const result = await db
      .prepare(`
        SELECT
          id,
          title,
          display_name,
          type,
          image_id,
          year
        FROM artworks
        WHERE published = 1 
        AND image_id IS NOT NULL
        ORDER BY year DESC, order_index DESC
      `)
      .all();

    const artworks = result.results.map(artwork => ({
      id: artwork.id,
      title: artwork.title,
      display_name: artwork.display_name,
      type: artwork.type,
      image_id: artwork.image_id,
      year: artwork.year,
      thumbnailUrl: `https://imagedelivery.net/${CF_IMAGES_ACCOUNT_HASH}/${artwork.image_id}/w=600,h=400,fit=cover`
    }));

    return {
      artworks,
      cfImagesHash: CF_IMAGES_ACCOUNT_HASH
    };
  } catch (error) {
    console.error('Error loading wallpapers data:', error);
    
    return {
      artworks: [],
      cfImagesHash: CF_IMAGES_ACCOUNT_HASH
    };
  }
}
