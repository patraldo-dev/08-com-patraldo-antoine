// src/routes/+page.server.js
export async function load({ platform, locals }) {
  try {
    const db = platform?.env?.DB;
    
    if (!db) {
      console.warn('DB not available');
      return { artworks: [] };
    }

    // Load featured artworks for the sketchbook
    const result = await db
      .prepare(`
        SELECT 
          id,
          title,
          description,
          type,
          thumbnailId,
          thumbnailUrl,
          imageUrl,
          videoId,
          date,
          story,
          tags
        FROM artworks
        WHERE published = 1
        ORDER BY date DESC
        LIMIT 6
      `)
      .all();

    // Parse tags if stored as JSON strings
    const artworks = result.results.map(artwork => ({
      ...artwork,
      tags: artwork.tags ? JSON.parse(artwork.tags) : [],
      date: artwork.date || new Date().toISOString().split('T')[0]
    }));

    return {
      artworks
    };
  } catch (error) {
    console.error('Error loading artworks:', error);
    return { artworks: [] };
  }
}
