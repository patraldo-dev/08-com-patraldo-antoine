// src/routes/api/webhooks/cloudflare/+server.js
import { json } from '@sveltejs/kit';

export async function POST({ request, platform }) {
  // Get the raw body for debugging
  const body = await request.text();
  console.log('Webhook received:', body);
  
  try {
    const payload = JSON.parse(body);
    console.log('Parsed payload:', payload);
    
    // Handle Cloudflare Images webhook
    if (payload.event === 'image.uploaded') {
      const { id: imageId, meta } = payload;
      
      try {
        // Check if artwork already exists
        const existing = await platform.env.ARTWORKS_DB.prepare('SELECT * FROM artworks WHERE image_id = ?')
          .bind(imageId)
          .first();
        
        if (existing) {
          return json({ success: true, message: 'Artwork already exists' });
        }
        
        // Create new artwork entry
        const { success } = await platform.env.ARTWORKS_DB.prepare(`
          INSERT INTO artworks (title, type, image_id, description, year)
          VALUES (?, ?, ?, ?, ?)
        `).bind(
          `Untitled ${meta?.name || 'Artwork'}`,
          'still',
          imageId,
          'Description pending',
          new Date().getFullYear()
        ).run();
        
        if (!success) {
          throw new Error('Failed to insert artwork');
        }
        
        return json({ success: true, imageId });
      } catch (error) {
        console.error('Error inserting artwork:', error);
        return json({ error: 'Failed to process image upload' }, { status: 500 });
      }
    }
    
    // Handle Cloudflare Stream webhook
    if (payload.event === 'video.uploaded') {
      const { uid: videoId, meta } = payload;
      
      try {
        // Check if artwork already exists
        const existing = await platform.env.ARTWORKS_DB.prepare('SELECT * FROM artworks WHERE video_id = ?')
          .bind(videoId)
          .first();
        
        if (existing) {
          return json({ success: true, message: 'Artwork already exists' });
        }
        
        // Create new artwork entry
        const { success } = await platform.env.ARTWORKS_DB.prepare(`
          INSERT INTO artworks (title, type, video_id, description, year)
          VALUES (?, ?, ?, ?, ?)
        `).bind(
          `Untitled ${meta?.name || 'Video'}`,
          'animation',
          videoId,
          'Description pending',
          new Date().getFullYear()
        ).run();
        
        if (!success) {
          throw new Error('Failed to insert artwork');
        }
        
        return json({ success: true, videoId });
      } catch (error) {
        console.error('Error inserting artwork:', error);
        return json({ error: 'Failed to process video upload' }, { status: 500 });
      }
    }
    
    return json({ error: 'Unsupported event type' }, { status: 400 });
  } catch (error) {
    console.error('Error parsing webhook payload:', error);
    return json({ error: 'Invalid JSON payload' }, { status: 400 });
  }
}
