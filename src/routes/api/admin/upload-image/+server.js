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
      throw error(500, 'Cloudflare API token not configured');
    }

    if (!accountId) {
      throw error(500, 'Cloudflare Account ID not configured');
    }

    // For Cloudflare Workers, we need to send the file directly in the body
    // Cloudflare Images API v1 accepts the raw file in the request body
    const response = await fetch(`https://api.cloudflare.com/client/v4/accounts/${accountId}/images/v1`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${apiToken}`,
        // Don't set Content-Type header, let it be set automatically with boundary
      },
      body: file
    });

    const data = await response.json();

    if (!data.success) {
      console.error('Cloudflare API error:', data.errors);
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