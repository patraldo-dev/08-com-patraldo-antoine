// src/routes/api/story/[id]/+server.js
import { json } from '@sveltejs/kit';

/** @type {import('./$types').RequestHandler} */
export async function GET({ params, platform }) {
  const { id } = params;
  
  try {
    const db = platform?.env?.ARTWORKS_DB;
    
    if (!db) {
      return json(
        { 
          success: false, 
          error: 'Database not available',
          content: []
        },
        { status: 500 }
      );
    }
    
    // Fetch story content ordered by order_index
    const { results } = await db
      .prepare(`
        SELECT 
          id,
          content_type,
          content_text,
          media_id,
          video_id,
          order_index
        FROM story_content
        WHERE artwork_id = ?
        ORDER BY order_index ASC
      `)
      .bind(id)
      .all();
    
    console.log(`Fetched ${results?.length || 0} story blocks for artwork ${id}`);
    
    return json({
      success: true,
      content: results || []
    });
    
  } catch (error) {
    console.error('Error fetching story content:', error);
    return json(
      { 
        success: false, 
        error: 'Failed to load story content',
        content: [],
        details: error.message
      },
      { status: 500 }
    );
  }
}
