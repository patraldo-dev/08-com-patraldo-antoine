import { json } from '@sveltejs/kit';

export async function POST({ request, platform }) {
  try {
    // Get metadata from the request
    const { metadata } = await request.json();
    
    // Get secrets from platform.env
    const apiToken = platform.env.CLOUDFLARE_API_TOKEN;
    const accountId = platform.env.CLOUDFLARE_ACCOUNT_ID;
    
    // Request a one-time upload URL from Cloudflare
    const response = await fetch(`https://api.cloudflare.com/client/v4/accounts/${accountId}/images/v2/direct_upload`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${apiToken}`,
      },
      body: new URLSearchParams({
        requireSignedURLs: 'true',
        metadata: JSON.stringify(metadata || {})
      })
    });
    
    const data = await response.json();
    
    if (!data.success) {
      throw new Error(data.errors[0].message);
    }
    
    // Store the pending upload in the database
    const { success } = await platform.env.ARTWORKS_DB.prepare(`
      INSERT INTO pending_uploads (image_id, title, description, year, status)
      VALUES (?, ?, ?, ?, ?)
    `).bind(
      data.result.id,
      metadata?.title || 'Untitled',
      metadata?.description || 'Description pending',
      metadata?.year || new Date().getFullYear(),
      'pending'
    ).run();
    
    if (!success) {
      throw new Error('Failed to store pending upload');
    }
    
    return json({
      success: true,
      uploadURL: data.result.uploadURL,
      imageId: data.result.id
    });
  } catch (error) {
    console.error('Error generating upload URL:', error);
    return json({ error: error.message }, { status: 500 });
  }
}
