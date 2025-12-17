import { json } from '@sveltejs/kit';

export async function PUT({ request, platform, params }) {
  try {
    const { id } = params;
    const { title, type, image_id, video_id, description, year, featured } = await request.json();
    
    const { success } = await platform.env.ARTWORKS_DB.prepare(`
      UPDATE artworks 
      SET title = ?, type = ?, image_id = ?, video_id = ?, description = ?, year = ?, featured = ?, updated_at = CURRENT_TIMESTAMP
      WHERE id = ?
    `).bind(title, type, image_id, video_id, description, year, featured ? 1 : 0, id).run();
    
    if (!success) {
      throw new Error('Failed to update artwork');
    }
    
    return json({ success: true });
  } catch (error) {
    console.error('Error updating artwork:', error);
    return json({ error: 'Failed to update artwork' }, { status: 500 });
  }
}
