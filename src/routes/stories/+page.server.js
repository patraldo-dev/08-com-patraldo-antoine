// src/routes/stories/+page.server.js
import { CF_IMAGES_ACCOUNT_HASH, CUSTOM_DOMAIN } from '$lib/config.js';

/** @type {import('./$types').PageServerLoad} */
export async function load({ platform, cookies }) {
  try {
    const preferredLanguage = cookies.get('preferredLanguage') || 'es';
    
    // Fetch all artworks with stories enabled from ARTWORKS_DB
    const result = await platform.env.ARTWORKS_DB.prepare(`
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
        story_enabled,
        story_intro
      FROM artworks
      WHERE published = 1 AND story_enabled = 1
      ORDER BY order_index DESC, year DESC
    `).all();
    
    // Transform to include image URLs
    const stories = result.results.map(artwork => {
      const thumbnailUrl = artwork.image_id 
        ? `https://imagedelivery.net/${CF_IMAGES_ACCOUNT_HASH}/${artwork.image_id}/thumbnail`
        : null;
      
      return {
        id: artwork.id,
        title: artwork.title,
        display_name: artwork.display_name,
        slug: artwork.slug,
        description: artwork.description,
        story_intro: artwork.story_intro,
        type: artwork.type,
        thumbnailId: artwork.image_id,
        thumbnailUrl: thumbnailUrl,
        videoId: artwork.video_id,
        video_id: artwork.video_id,
        image_id: artwork.image_id,
        year: artwork.year
      };
    });
    
    console.log(`Loaded ${stories.length} story-enabled artworks`);
    
    return { 
      stories,
      preferredLanguage 
    };
  } catch (error) {
    console.error('Error loading stories:', error);
    return { 
      stories: [],
      preferredLanguage: 'es',
      error: 'Failed to load stories'
    };
  }
}
