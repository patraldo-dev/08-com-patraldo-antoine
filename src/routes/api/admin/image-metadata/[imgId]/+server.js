import { json, error } from '@sveltejs/kit';

export async function GET({ params, platform, locals }) {
  // Use locals from hooks instead of session KV
  if (!locals.user || !locals.isAdmin) {
    throw error(403, 'Forbidden: Admin access required');
  }

  const { imgId } = params;

  const env = platform?.env;
  if (!env) return json({ error: 'Server not configured' }, { status: 500 });

  try {
    // Get secrets from env
    const apiToken = (await env.CLOUDFLARE_API_TOKEN?.get?.()) ?? null;
    const accountId = env.CLOUDFLARE_ACCOUNT_ID;

    // Fetch image details from Cloudflare
    const response = await fetch(`https://api.cloudflare.com/client/v4/accounts/${accountId}/images/v1/${imgId}`, {
      headers: {
        'Authorization': `Bearer ${apiToken}`,
      }
    });

    const data = await response.json();

    if (!data.success) {
      const errorMessage = data.errors?.[0]?.message || 'Failed to fetch image metadata';
      throw error(500, errorMessage);
    }

    const image = data.result;

    return json({
      success: true,
      title: image.filename || image.id,
      filename: image.filename,
      width: image.width,
      height: image.height,
      format: image.format,
      size: image.size,
      uploaded: image.uploaded
    });
  } catch (/** @type {any} */ err) {
    console.error('Get image metadata error:', err);
    throw error(500, err.message || 'Failed to fetch image metadata');
  }
}