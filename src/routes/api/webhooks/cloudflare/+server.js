import { json } from '@sveltejs/kit';
import crypto from 'crypto';

// Function to verify webhook signature
function verifySignature(signature, payload, secret) {
  const hmac = crypto.createHmac('sha256', secret);
  const digest = hmac.update(payload).digest('hex');
  return signature === `sha256=${digest}`;
}

export async function POST({ request, platform }) {
  // Get the signature from headers
  const signature = request.headers.get('Webhook-Signature') || '';
  
  // Get the raw body for verification
  const body = await request.text();
  const payload = JSON.parse(body);
  
  // Verify the signature (replace with your actual secret)
  const secret = 'YOUR_SECRET_HERE'; // Replace with your actual secret
  if (!verifySignature(signature, body, secret)) {
    return json({ error: 'Invalid signature' }, { status: 401 });
  }
  
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
        meta?.title || `Untitled ${meta?.name || 'Artwork'}`,
        'still',
        imageId,
        meta?.description || 'Description pending',
        meta?.year || new Date().getFullYear()
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
        meta?.title || `Untitled ${meta?.name || 'Video'}`,
        'animation',
        videoId,
        meta?.description || 'Description pending',
        meta?.year || new Date().getFullYear()
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
}
