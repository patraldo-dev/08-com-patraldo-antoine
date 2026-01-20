// src/routes/stories/+page.server.js
import { CF_IMAGES_ACCOUNT_HASH } from '$lib/config.js';

export async function load({ platform, locals }) {  // ✅ Changed from 'event' to 'locals'
  // 1. GET AUTH STATUS FROM HOOK (The Single Source of Truth)
  // We don't check headers or cookies manually here.
  const isAdmin = locals.user?.role === 'admin';  // ✅ Use locals directly
  
  const dbStories = platform?.env?.stories_db;
  const dbArtworks = platform?.env?.ARTWORKS_DB;
  
  if (!dbStories || !dbArtworks) {
    console.log("Stories Index: Database bindings missing.");
    return { stories: [], isAdmin };
  }
  
  try {
    let allStories = [];
    let usedArtworkIds = new Set();
    
    // 2. FETCH FULL STORIES
    const newStoriesResult = await dbStories.prepare(`
      SELECT 
        s.id as story_id,
        s.title as story_title,
        s.slug as story_slug,
        s.created_at as story_created_at,
        sc.artwork_id
      FROM stories s
      LEFT JOIN story_chapters sc ON s.id = sc.story_id AND sc.order_index = 1
      ORDER BY s.created_at DESC
    `).all();
    
    const artworksResult = await dbArtworks.prepare(`
      SELECT 
        id, 
        title, 
        display_name, 
        image_id, 
        story_intro, 
        year, 
        created_at
      FROM artworks
      WHERE story_enabled = 1
      ORDER BY created_at DESC
    `).all();
    
    const artworksMap = new Map();
    artworksResult.results.forEach(art => {
      artworksMap.set(art.id, art);
    });
    
    const newStories = newStoriesResult.results.map(row => {
      const artwork = artworksMap.get(row.artwork_id);
      if (artwork) usedArtworkIds.add(row.artwork_id);
      return {
        id: row.story_id,
        title: row.story_title,
        slug: row.story_slug,
        description: artwork?.story_intro || '',
        year: artwork?.year || null,
        display_name: artwork?.display_name || row.story_title,
        thumbnailUrl: artwork?.image_id
          ? `https://imagedelivery.net/${CF_IMAGES_ACCOUNT_HASH}/${artwork.image_id}/gallery`
          : '/placeholder.png',
        type: 'full',
        created_at: row.story_created_at
      };
    });
    
    allStories = [...allStories, ...newStories];
    
    const introStories = artworksResult.results
      .filter(art => !usedArtworkIds.has(art.id)) 
      .map(row => ({
        id: row.id,
        title: row.display_name || row.title,
        slug: null,
        description: row.story_intro || '',
        story_intro: row.story_intro || '',
        year: row.year,
        display_name: row.display_name,
        thumbnailUrl: row.image_id
          ? `https://imagedelivery.net/${CF_IMAGES_ACCOUNT_HASH}/${row.image_id}/gallery`
          : '/placeholder.png',
        type: 'intro',
        created_at: row.created_at
      }));
    
    allStories = [...allStories, ...introStories];
    allStories.sort((a, b) => new Date(b.created_at) - new Date(a.created_at));
    
    console.log(`Stories loaded: ${allStories.length} total`);
    
    // 3. RETURN DATA
    return { stories: allStories, isAdmin };
  } catch (e) {
    console.error("Error loading combined stories:", e);
    return { stories: [], isAdmin: false };
  }
}
