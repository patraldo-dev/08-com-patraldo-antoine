import { json } from '@sveltejs/kit';

export async function POST({ request, platform }) {
  const signature = request.headers.get('Webhook-Signature');
  const body = await request.text();
  
  // Verify the webhook signature (you'll need to set up a secret in Cloudflare)
  // This is a simplified example; in production, use proper verification
  // const isValid = verifySignature(signature, body, SECRET);
  // if (!isValid) {
  //   return json({ error: 'Invalid signature' }, { status: 401 });
  // }
  
  const payload = JSON.parse(body);
  
  // Handle Cloudflare Images webhook
  if (payload.event === 'image.uploaded') {
    const { id: imageId, meta } = payload;
    
    try {
      const { success } = await platform.env.DB.prepare(`
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
      const { success } = await platform.env.DB.prepare(`
        INSERT INTO artworks (title, type, video_id, description, year)
        VALUES (?, ?, ?, ?, ?)
      `).bind(
        `Untitled ${meta?.name || 'Video'}`,
        'animation',
        null, // We don't have an image_id for videos, but you might want to generate a thumbnail
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
}
