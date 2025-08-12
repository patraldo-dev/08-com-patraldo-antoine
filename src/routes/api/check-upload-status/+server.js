import { json } from '@sveltejs/kit';

export async function POST({ request, platform }) {
  try {
    const { imageId } = await request.json();
    
    // Check the image status with Cloudflare
    const response = await fetch(`https://api.cloudflare.com/client/v4/accounts/YOUR_ACCOUNT_ID/images/v1/${imageId}`, {
      headers: {
        'Authorization': 'Bearer YOUR_API_TOKEN',
      }
    });
    
    const data = await response.json();
    
    if (!data.success) {
      throw new Error(data.errors[0].message);
    }
    
    // If the image is no longer in draft status, it's been uploaded
    if (!data.result.draft) {
      // Get the pending upload details
      const pendingUpload = await platform.env.ARTWORKS_DB.prepare('SELECT * FROM pending_uploads WHERE image_id = ?')
        .bind(imageId)
        .first();
      
      if (pendingUpload) {
        // Add the artwork to the database
        const { success } = await platform.env.ARTWORKS_DB.prepare(`
          INSERT INTO artworks (title, type, image_id, description, year)
          VALUES (?, ?, ?, ?, ?)
        `).bind(
          pendingUpload.title,
          'still',
          imageId,
          pendingUpload.description,
          pendingUpload.year
        ).run();
        
        if (!success) {
          throw new Error('Failed to add artwork to database');
        }
        
        // Remove the pending upload
        await platform.env.ARTWORKS_DB.prepare('DELETE FROM pending_uploads WHERE image_id = ?')
          .bind(imageId)
          .run();
        
        return json({
          success: true,
          status: 'uploaded',
          artwork: {
            title: pendingUpload.title,
            description: pendingUpload.description,
            year: pendingUpload.year
          }
        });
      }
    }
    
    return json({
      success: true,
      status: 'pending'
    });
  } catch (error) {
    console.error('Error checking upload status:', error);
    return json({ error: error.message }, { status: 500 });
  }
}
