// src/routes/+page.server.js
import { CF_IMAGES_ACCOUNT_HASH } from '$lib/config.js';

/**
 * Shuffle array using seeded random
 * @param {Array} array - Array to shuffle
 * @param {number} seed - Seed for consistent shuffling
 * @returns {Array} Shuffled array
 */
function shuffleArray(array, seed = null) {
  // Use today's date as seed for daily shuffle
  if (seed === null) {
    const today = new Date();
    seed = today.getFullYear() * 10000 + (today.getMonth() + 1) * 100 + today.getDate();
  }
  
  // Seeded random number generator
  const rng = (s) => {
    let x = Math.sin(s++) * 10000;
    return x - Math.floor(x);
  };
  
  const shuffled = [...array];
  for (let i = shuffled.length - 1; i > 0; i--) {
    const j = Math.floor(rng(seed + i) * (i + 1));
    [shuffled[i], shuffled[j]] = [shuffled[j], shuffled[i]];
  }
  return shuffled;
}

export async function load({ platform }) {
  try {
    const dbArtworks = platform?.env?.ARTWORKS_DB;
    const dbStories = platform?.env?.stories_db;
    
    // 1. FETCH ARTWORKS (From antoine-artworks)
    const result = await dbArtworks
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
          order_index,
          story_enabled,
          story_intro,
          created_at
        FROM artworks
        WHERE published = 1
        ORDER BY order_index DESC, year DESC
      `)
      .all();

    console.log(`Loaded ${result.results?.length || 0} artworks`);

    // Transform to match component expectations
    const artworks = result.results.map(artwork => {
      const thumbnailUrl = artwork.image_id 
        ? `https://imagedelivery.net/${CF_IMAGES_ACCOUNT_HASH}/${artwork.image_id}/thumbnail`
        : null;
      
      return {
        id: artwork.id,
        title: artwork.title,
        display_name: artwork.display_name,
        slug: artwork.slug,
        description: artwork.description,
        type: artwork.type,
        thumbnailId: artwork.image_id,
        videoId: artwork.video_id,
        video_id: artwork.video_id,
        image_id: artwork.image_id,
        date: artwork.year ? `${artwork.year}-01-01` : null,
        year: artwork.year,
        story_enabled: artwork.story_enabled || false,
        story_intro: artwork.story_intro || null,
        tags: []
      };
    });

    // Shuffle artworks with daily seed
    const shuffledArtworks = shuffleArray(artworks);

    // Filter artworks that have videos
    const videos = shuffledArtworks.filter(artwork => artwork.video_id);
    
    // Shuffle videos with daily seed
    const shuffledVideos = shuffleArray(videos);
    
    console.log(`Loaded ${shuffledArtworks.length} artworks (${shuffledArtworks.filter(a => a.story_enabled).length} with stories)`);
    console.log(`Loaded ${shuffledVideos.length} videos for daily rotation`);
    
    return { 
      artworks: shuffledArtworks,
      videos: shuffledVideos
    };
    
  } catch (error) {
    console.error('Error loading page data:', error);
    return { artworks: [], videos: [] };
  }
}
