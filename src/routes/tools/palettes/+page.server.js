// src/routes/tools/palettes/+page.server.js
import { CF_IMAGES_ACCOUNT_HASH } from '$lib/config.js';

export async function load({ platform }) {
  try {
    const db = platform?.env?.ARTWORKS_DB;
    
    if (!db) {
      return { artworks: [] };
    }

    const result = await db.prepare(`
      SELECT 
        id,
        title,
        display_name,
        image_id,
        year
      FROM artworks
      WHERE published = 1
      ORDER BY RANDOM()
      LIMIT 10
    `).all();

    const artworks = result.results.map(artwork => ({
      id: artwork.id,
      title: artwork.title,
      display_name: artwork.display_name,
      thumbnailUrl: `https://imagedelivery.net/${CF_IMAGES_ACCOUNT_HASH}/${artwork.image_id}/thumbnail`,
      year: artwork.year
    }));

    return { artworks };
  } catch (error) {
    console.error('Error loading palettes:', error);
    return { artworks: [] };
  }
}
