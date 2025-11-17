export async function POST({ request, platform, getClientAddress }) {
  try {
    const db = platform?.env?.ARTWORKS_DB;
    if (!db) {
      return json({ error: 'Database unavailable' }, { status: 503 });
    }

    const { eventType, artworkId, metadata, displayName } = await request.json();
    
    const ipAddress = getClientAddress();
    const ipHash = await hashString(ipAddress);
    const country = request.headers.get('cf-ipcountry') || 'unknown';
    const userAgent = request.headers.get('user-agent') || 'unknown';

    await db.prepare(`
      INSERT INTO analytics (event_type, artwork_id, display_name, session_id, user_agent, ip_hash, country, metadata)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    `).bind(
      eventType,
      artworkId,
      displayName || null,
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
