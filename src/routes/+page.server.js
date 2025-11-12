// src/routes/+page.server.js
import { CF_IMAGES_ACCOUNT_HASH, CUSTOM_DOMAIN } from '$lib/config.js';

export async function load({ platform }) {
  try {
    const db = platform?.env?.ARTWORKS_DB;
    
    if (!db) {
      console.error('❌ DB not available in platform.env');
      return { artworks: [], debug: 'ARTWORKS_DB not available' };
    }

    console.log('✅ DB connection available');

    // First, check total count
    const countResult = await db
      .prepare("SELECT COUNT(*) as total FROM artworks")
      .first();
    
    console.log(`📊 Total artworks in database: ${countResult.total}`);

    // Check published count
    const publishedCount = await db
      .prepare("SELECT COUNT(*) as total FROM artworks WHERE published = 1")
      .first();
    
    console.log(`📊 Published artworks: ${publishedCount.total}`);

    // Query ALL artworks first (ignore published) to see what we have
    const allResult = await db
      .prepare(`
        SELECT 
          id, title, type, image_id, video_id, 
          description, year, published
        FROM artworks
        ORDER BY order_index DESC, year DESC
        LIMIT 10
      `)
      .all();

    console.log(`📦 Raw query returned ${allResult.results.length} artworks`);
    console.log('📝 First artwork:', JSON.stringify(allResult.results[0]));

    // Now try with published filter
    const result = await db
      .prepare(`
        SELECT 
          id, title, type, image_id, video_id,
          description, year, featured, published
        FROM artworks
        WHERE published = 1
        ORDER BY order_index DESC, year DESC
        LIMIT 6
      `)
      .all();

    console.log(`✅ Filtered query returned ${result.results.length} published artworks`);

    // Transform to match what the Sketchbook component expects
    const artworks = result.results.map(artwork => {
      // Build Cloudflare Images URL from image_id
      const thumbnailUrl = artwork.image_id 
        ? `https://${CUSTOM_DOMAIN}/cdn-cgi/imagedelivery/${CF_IMAGES_ACCOUNT_HASH}/${artwork.image_id}/thumbnail`
        : null;
      
      console.log(`🎨 Processing artwork ${artwork.id}: "${artwork.title}" (image_id: ${artwork.image_id})`);
      
      return {
        id: artwork.id,
        title: artwork.title,
        description: artwork.description,
        type: artwork.type,
        thumbnailId: artwork.image_id,
        thumbnailUrl: thumbnailUrl,
        videoId: artwork.video_id,
        date: artwork.year ? `${artwork.year}-01-01` : null,
        story: null,
        tags: []
      };
    });

    console.log(`🎉 Returning ${artworks.length} artworks to page`);
    
    return { 
      artworks,
      debug: {
        totalInDb: countResult.total,
        publishedCount: publishedCount.total,
        returnedCount: artworks.length
      }
    };
    
  } catch (error) {
    console.error('❌ Error loading artworks:', error);
    console.error('❌ Error stack:', error.stack);
    return { 
      artworks: [], 
      debug: `Error: ${error.message}` 
    };
  }
}
