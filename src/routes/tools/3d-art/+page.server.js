export async function load({ platform }) {
  console.log('=== Load function START ===');
  
  const db = platform?.env?.ARTWORKS_DB;
  console.log('DB available:', !!db);
  
  if (!db) {
    console.error('DB not available');
    return { artworks: [] };
  }

  try {
    console.log('Executing DB query...');
    const { results } = await db.prepare(`
      SELECT id, title, slug, type, image_id, video_id, description, year
      FROM artworks
      WHERE published = 1
      ORDER BY order_index ASC, id DESC
    `).all();
    
    console.log('Query results:', results.length);
    
    const artworks = results.map(artwork => {
      console.log(`Mapping artwork ${artwork.id}`);
      
      return {
        id: artwork.id,
        title: artwork.title,
        slug: artwork.slug,
        type: artwork.type,
        imageId: artwork.image_id,
        videoId: artwork.video_id,
        description: artwork.description,
        year: artwork.year,
        transform: {
          rotation: { x: 0, y: 0, z: 0 },
          position: { x: 0, y: 0, z: 0 },
          scale: { x: 1, y: 1, z: 1 }
        }
      };
    });
    
    console.log('Mapped artworks:', artworks.length);
    
    return { artworks };
    
  } catch (error) {
    console.error('=== ERROR ===');
    console.error('Message:', error.message);
    console.error('Stack:', error.stack);
    return { artworks: [] };
  }
}
