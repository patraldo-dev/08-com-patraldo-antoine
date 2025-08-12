import { json } from '@sveltejs/kit';

export async function GET({ platform }) {
  try {
    const { results } = await platform.env.ARTWORKS_DB.prepare('SELECT * FROM artworks ORDER BY created_at DESC').all();
    return json(results);
  } catch (error) {
    console.error('Error fetching artworks:', error);
    return json({ error: 'Failed to fetch artworks' }, { status: 500 });
  }
}

export async function POST({ request, platform }) {
  try {
    const { title, type, image_id, video_id, description, year, featured } = await request.json();
    
    const { success, results } = await platform.env.ARTWORKS_DB.prepare(`
      INSERT INTO artworks (title, type, image_id, video_id, description, year, featured)
      VALUES (?, ?, ?, ?, ?, ?, ?)
    `).bind(title, type, image_id, video_id, description, year, featured ? 1 : 0).run();
    
    if (!success) {
      throw new Error('Failed to create artwork');
    }
    
    return json({ success: true, id: results.meta.last_row_id });
  } catch (error) {
    console.error('Error creating artwork:', error);
    return json({ error: 'Failed to create artwork' }, { status: 500 });
  }
}
