// src/routes/stories/+page.server.js
import { CF_IMAGES_ACCOUNT_HASH } from '$lib/config.js';

export async function load({ request, platform }) {
  const dbStories = platform?.env?.stories_db;
  const dbArtworks = platform?.env?.ARTWORKS_DB;

  // 1. CHECK IF ADMIN
  const url = new URL(request.url);
  let isAdmin = false;
  
  if (url.hostname === 'antoine.patraldo.com') {
    // Check for Cloudflare Access header
    const cfJwt = request.headers.get('cf-access-jwt-assertion');
    isAdmin = !!cfJwt;
  } 
  // Allow admin access in dev/preview
  else if (url.hostname === 'localhost' || url.hostname.endsWith('.workers.dev')) {
    isAdmin = true; 
  }

  console.log("=== STORIES DEBUG ===");
  console.log("dbStories exists:", !!dbStories);
  console.log("dbArtworks exists:", !!dbArtworks);
  console.log("Is Admin:", isAdmin);
  
  if (!dbStories || !dbArtworks) {
    console.log("Stories Index: Database bindings missing.");
    return { stories: [], isAdmin };
  }
  
  try {
    let allStories = [];
    let usedArtworkIds = new Set();
    
    //1. FETCH FULL STORIES (From stories_db)
    // We fetch stories and their linked artwork_id
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
    
    console.log("Full stories query result:", newStoriesResult.results?.length || 0, "rows");
    
    // 2. FETCH ARTWORKS (From ARTWORKS_DB)
    // We fetch ALL artworks that are story_enabled
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
    
    console.log("Artworks query result:", artworksResult.results?.length || 0, "rows");
    console.log("First artwork sample:", artworksResult.results?.[0]);
    
    // Create a map of artworks for easy lookup
    const artworksMap = new Map();
    artworksResult.results.forEach(art => {
      artworksMap.set(art.id, art);
    });
    
    // 3. CREATE FULL STORY OBJECTS
    const newStories = newStoriesResult.results.map(row => {
      const artwork = artworksMap.get(row.artwork_id);
      
      if (artwork) {
        // Mark this artwork as "used" so we don't list it as an intro story later
        usedArtworkIds.add(row.artwork_id);
      }
      
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
    
    // 4. CREATE INTRO STORY OBJECTS
    // These are artworks that have story_enabled=1 but were NOT linked to a story
    const introStories = artworksResult.results
      .filter(art => !usedArtworkIds.has(art.id)) // Filter out the ones already used
      .map(row => ({
        id: row.id,
        title: row.display_name || row.title,
        slug: null, // No full page
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
    
    // 5. SORT ALL TOGETHER
    allStories.sort((a, b) => new Date(b.created_at) - new Date(a.created_at));
    
    console.log(`Stories loaded: ${allStories.length} total (${newStories.length} full, ${introStories.length} intro)`);
    
    return { stories: allStories, isAdmin };
  } catch (e) {
    console.error("Error loading combined stories:", e);
    return { stories: [], isAdmin };
  }
}
