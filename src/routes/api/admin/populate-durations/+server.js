// src/routes/api/admin/populate-durations/+server.js
import { json } from '@sveltejs/kit';
import { CineDatabase } from '$lib/server/cine-db.js';

/**
 * Admin endpoint to populate video durations from Cloudflare Stream
 * GET /api/admin/populate-durations
 */
export async function GET({ platform, url }) {
  // Simple auth check (optional - add your own auth here)
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
    // Get all artworks with videos
    const result = await platform.env.ARTWORKS_DB
      .prepare('SELECT id, video_id, title FROM artworks WHERE video_id IS NOT NULL')
      .all();

    const artworks = result.results || [];
    const results = [];

    for (const artwork of artworks) {
      try {
        // Fetch duration from Stream API
        const duration = await db.getVideoDuration(
          artwork.video_id,
          artwork.id,
          accountId,
          apiToken
        );

        results.push({
          id: artwork.id,
          title: artwork.title,
          duration: duration,
          status: 'success'
        });

        // Small delay to respect rate limits
        await new Promise(resolve => setTimeout(resolve, 100));
      } catch (err) {
        results.push({
          id: artwork.id,
          title: artwork.title,
          error: err.message,
          status: 'error'
        });
      }
    }

    const successCount = results.filter(r => r.status === 'success').length;
    const errorCount = results.filter(r => r.status === 'error').length;

    return json({
      success: true,
      processed: artworks.length,
      successCount,
      errorCount,
      results
    });

  } catch (err) {
    return json({ 
      error: 'Failed to populate durations', 
      details: err.message 
    }, { status: 500 });
  }
}
