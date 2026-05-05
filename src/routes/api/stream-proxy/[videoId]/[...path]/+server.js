import { json } from '@sveltejs/kit';

export async function GET({ params, platform, url }) {
  const { videoId, path } = params;
  const accountId = platform.env.CF_ACCOUNT_ID;
  const customerCode = platform.env.CLOUDFLARE_STREAM_CUSTOMER_CODE;
  const token = await platform.env.CLOUDFLARE_API_TOKEN.get();

  if (!accountId || !customerCode || !token) {
    return json({ error: 'Not configured' }, { status: 500 });
  }

  // Generate signed token (valid 1 hour)
  const tokenRes = await fetch(
    `https://api.cloudflare.com/client/v4/accounts/${accountId}/stream/${videoId}/token`,
    {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${token}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({ maxAgeSeconds: 3600 })
    }
  );
  const tokenData = await tokenRes.json();
  
  if (!tokenData.success || !tokenData.result.token) {
    return json({ error: 'Failed to generate token', details: tokenData.errors }, { status: 500 });
  }

  const signedToken = tokenData.result.token;

  // Build the upstream URL — proxy any segment file (.m3u8, .ts, .mp4)
  const upstreamUrl = `https://customer-${customerCode}.cloudflarestream.com/${videoId}/${path}?token=${signedToken}`;

  const upstreamRes = await fetch(upstreamUrl);

  if (!upstreamRes.ok) {
    return json({ error: `Upstream ${upstreamRes.status}` }, { status: upstreamRes.status });
  }

  // Determine content type
  const contentType = path.endsWith('.m3u8') ? 'application/vnd.apple.mpegurl'
    : path.endsWith('.ts') ? 'video/mp2t'
    : path.endsWith('.mp4') ? 'video/mp4'
    : path.endsWith('.mpd') ? 'application/dash+xml'
    : upstreamRes.headers.get('content-type') || 'application/octet-stream';

  return new Response(upstreamRes.body, {
    status: 200,
    headers: {
      'Content-Type': contentType,
      'Access-Control-Allow-Origin': '*',
      'Cache-Control': 'public, max-age=3600'
    }
  });
}
