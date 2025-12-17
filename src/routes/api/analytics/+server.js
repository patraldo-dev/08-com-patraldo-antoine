// src/routes/api/analytics/+server.js
import { json } from '@sveltejs/kit';

export async function POST({ request, platform, getClientAddress }) {
  try {
    const db = platform?.env?.ARTWORKS_DB;
    if (!db) {
      return json({ error: 'Database unavailable' }, { status: 503 });
    }

    const { eventType, artworkId, metadata, display_name } = await request.json();
    
    // Generate session ID from IP (hashed for privacy)
    const ipAddress = getClientAddress();
    const ipHash = await hashString(ipAddress);
    
    // Get country from Cloudflare headers
    const country = request.headers.get('cf-ipcountry') || 'unknown';
    const userAgent = request.headers.get('user-agent') || 'unknown';

    await db.prepare(`
      INSERT INTO analytics (event_type, artwork_id, display_name, session_id, user_agent, ip_hash, country, metadata)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    `).bind(
      eventType,
      artworkId,
      display_name || null,
      ipHash,
      userAgent,
      ipHash,
      country,
      JSON.stringify(metadata || {})
    ).run();

    return json({ success: true });
  } catch (error) {
    console.error('Analytics error:', error);
    return json({ error: 'Failed to record analytics' }, { status: 500 });
  }
}

// Get analytics data
export async function GET({ platform, url }) {
  try {
    const db = platform?.env?.ARTWORKS_DB;
    if (!db) {
      return json({ error: 'Database unavailable' }, { status: 503 });
    }

    const artworkId = url.searchParams.get('artworkId');
    const days = parseInt(url.searchParams.get('days') || '30');

    // Total visits per artwork WITH display_name
    const visits = await db.prepare(`
      SELECT 
        artwork_id,
        display_name,
        COUNT(*) as visit_count,
        COUNT(DISTINCT session_id) as unique_visitors
      FROM analytics
      WHERE event_type = 'visit'
        AND timestamp >= datetime('now', '-' || ? || ' days')
        ${artworkId ? 'AND artwork_id = ?' : ''}
      GROUP BY artwork_id, display_name
      ORDER BY visit_count DESC
    `).bind(days, ...(artworkId ? [artworkId] : [])).all();

    // Favorites count WITH display_name
    const favorites = await db.prepare(`
      SELECT 
        artwork_id,
        display_name,
        SUM(CASE WHEN event_type = 'favorite' THEN 1 ELSE -1 END) as net_favorites
      FROM analytics
      WHERE event_type IN ('favorite', 'unfavorite')
        AND timestamp >= datetime('now', '-' || ? || ' days')
        ${artworkId ? 'AND artwork_id = ?' : ''}
      GROUP BY artwork_id, display_name
      HAVING net_favorites > 0
      ORDER BY net_favorites DESC
    `).bind(days, ...(artworkId ? [artworkId] : [])).all();

    // Geographic distribution
    const countries = await db.prepare(`
      SELECT country, COUNT(*) as count
      FROM analytics
      WHERE event_type = 'visit'
        AND timestamp >= datetime('now', '-' || ? || ' days')
      GROUP BY country
      ORDER BY count DESC
      LIMIT 10
    `).bind(days).all();

    // Average time spent per artwork
    const timeSpent = await db.prepare(`
      SELECT 
        artwork_id,
        display_name,
        AVG(CAST(json_extract(metadata, '$.seconds') AS INTEGER)) as avg_seconds,
        MAX(CAST(json_extract(metadata, '$.seconds') AS INTEGER)) as max_seconds
      FROM analytics
      WHERE event_type = 'time_spent'
        AND json_extract(metadata, '$.final') = 'true'
        AND timestamp >= datetime('now', '-' || ? || ' days')
      GROUP BY artwork_id, display_name
      ORDER BY avg_seconds DESC
    `).bind(days).all();

    // Share statistics
    const shares = await db.prepare(`
      SELECT 
        artwork_id,
        display_name,
        json_extract(metadata, '$.platform') as platform,
        COUNT(*) as share_count
      FROM analytics
      WHERE event_type LIKE 'share_%'
        AND timestamp >= datetime('now', '-' || ? || ' days')
      GROUP BY artwork_id, display_name, platform
      ORDER BY share_count DESC
    `).bind(days).all();

    // Story completion rate
    const stories = await db.prepare(`
      SELECT 
        artwork_id,
        display_name,
        SUM(CASE WHEN event_type = 'story_start' THEN 1 ELSE 0 END) as starts,
        SUM(CASE WHEN event_type = 'story_complete' THEN 1 ELSE 0 END) as completions,
        ROUND(CAST(SUM(CASE WHEN event_type = 'story_complete' THEN 1 ELSE 0 END) AS FLOAT) / 
              NULLIF(SUM(CASE WHEN event_type = 'story_start' THEN 1 ELSE 0 END), 0) * 100, 1) as completion_rate
      FROM analytics
      WHERE event_type IN ('story_start', 'story_complete')
        AND timestamp >= datetime('now', '-' || ? || ' days')
      GROUP BY artwork_id, display_name
      HAVING starts > 0
      ORDER BY completion_rate DESC
    `).bind(days).all();

    // Video engagement
    const videos = await db.prepare(`
      SELECT 
        artwork_id,
        display_name,
        COUNT(DISTINCT session_id) as plays,
        SUM(CASE WHEN json_extract(metadata, '$.percent') = 100 THEN 1 ELSE 0 END) as completions,
        ROUND(CAST(SUM(CASE WHEN json_extract(metadata, '$.percent') = 100 THEN 1 ELSE 0 END) AS FLOAT) / 
              NULLIF(COUNT(DISTINCT session_id), 0) * 100, 1) as completion_rate
      FROM analytics
      WHERE event_type IN ('video_play', 'video_progress')
        AND timestamp >= datetime('now', '-' || ? || ' days')
      GROUP BY artwork_id, display_name
      ORDER BY plays DESC
    `).bind(days).all();

    return json({
      visits: visits.results,
      favorites: favorites.results,
      countries: countries.results,
      timeSpent: timeSpent.results,
      shares: shares.results,
      stories: stories.results,
      videos: videos.results
    });
  } catch (error) {
    console.error('Analytics fetch error:', error);
    return json({ error: 'Failed to fetch analytics' }, { status: 500 });
  }
}

async function hashString(str) {
  const encoder = new TextEncoder();
  const data = encoder.encode(str);
  const hashBuffer = await crypto.subtle.digest('SHA-256', data);
  const hashArray = Array.from(new Uint8Array(hashBuffer));
  return hashArray.map(b => b.toString(16).padStart(2, '0')).join('').slice(0, 16);
}
