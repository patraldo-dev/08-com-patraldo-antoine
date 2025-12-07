// src/routes/api/admin/populate-durations/+server.js
import { json } from '@sveltejs/kit';
import { CineDatabase } from '$lib/server/cine-db.js';

export async function GET({ platform, url }) {
  const authToken = url.searchParams.get('token');
  if (authToken !== 'your-secret-token-here') {
    return json({ error: 'Unauthorized' }, { status: 401 });
  }

  if (!platform?.env?.ARTWORKS_DB) {
    return json({ error: 'Database not configured' }, { status: 500 });
  }

  const accountId = platform.env.CLOUDFLARE_ACCOUNT_ID;
  const apiToken = platform.env.CLOUDFLARE_API_TOKEN;

  if (!accountId || !apiToken) {
    return json({ error: 'Missing Cloudflare credentials' }, { status: 500 });
  }

  const db = new CineDatabase(platform.env.ARTWORKS_DB);

  try {
    // Get just ONE artwork to test
    const result = await platform.env.ARTWORKS_DB
      .prepare('SELECT id, video_id, title FROM artworks WHERE video_id IS NOT NULL LIMIT 1')
      .all();

    const artworks = result.results || [];
    const debugInfo = [];

    for (const artwork of artworks) {
      try {
        // Call Stream API directly with debug info
        const streamResponse = await fetch(
          `https://api.cloudflare.com/client/v4/accounts/${accountId}/stream/${artwork.video_id}`,
          {
            headers: {
              'Authorization': `Bearer ${apiToken}`,
              'Content-Type': 'application/json'
            }
          }
        );

        const streamData = await streamResponse.json();
        
        debugInfo.push({
          artwork_id: artwork.id,
          artwork_title: artwork.title,
          video_id: artwork.video_id,
          api_status: streamResponse.status,
          api_success: streamData.success,
          api_errors: streamData.errors,
          duration_found: streamData.result?.duration,
          full_response: streamData
        });

      } catch (err) {
        debugInfo.push({
          artwork_id: artwork.id,
          error: err.message
        });
      }
    }

    return json({
      accountId: accountId.substring(0, 8) + '...', // Partial for security
      hasApiToken: !!apiToken,
      debugInfo
    });

  } catch (err) {
    return json({ 
      error: 'Failed to populate durations', 
      details: err.message 
    }, { status: 500 });
  }
}
