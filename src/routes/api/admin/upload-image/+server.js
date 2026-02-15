import { json, error } from '@sveltejs/kit';

export async function POST({ request, platform, locals }) {
  // Use locals from hooks instead of session KV
  if (!locals.user || !locals.isAdmin) {
    throw error(403, 'Forbidden: Admin access required');
  }

  try {
    // Parse the form data
    const formData = await request.formData();
    const file = formData.get('file');

    if (!file || typeof file === 'string') {
      throw error(400, 'No file provided');
    }

    // Get secrets from platform.env
    const apiToken = platform.env.CLOUDFLARE_API_TOKEN;
    const accountId = platform.env.CLOUDFLARE_ACCOUNT_ID;

    if (!apiToken) {
      console.error('Missing CLOUDFLARE_API_TOKEN');
      throw error(500, 'Cloudflare API token not configured');
    }

    if (!accountId) {
      console.error('Missing CLOUDFLARE_ACCOUNT_ID');
      throw error(500, 'Cloudflare Account ID not configured');
    }

    console.log('Attempting to upload image to Cloudflare...', { accountId: accountId.substring(0, 8) + '...' }); // Log partial ID for debugging
    
    // Create form data to send to Cloudflare API
    const cloudflareFormData = new FormData();
    cloudflareFormData.append('file', file);

    const response = await fetch(`https://api.cloudflare.com/client/v4/accounts/${accountId}/images/v1`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${apiToken}`,
        // Don't set Content-Type header, let it be set automatically with boundary
      },
      body: cloudflareFormData
    });

    console.log('Cloudflare API response status:', response.status);
    
    const data = await response.json();

    if (!data.success) {
      console.error('Cloudflare API error:', data.errors);
      console.error('Full response:', { status: response.status, data });
      const errorMessage = data.errors?.[0]?.message || 'Upload failed';
      throw error(500, errorMessage);
    }

    return json({
      success: true,
      imageId: data.result.id,
      filename: file.name
    });
  } catch (err) {
    console.error('Upload image error:', err);
    throw error(500, err.message || 'Failed to upload image');
  }
}