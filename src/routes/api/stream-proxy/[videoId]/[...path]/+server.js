import { json } from '@sveltejs/kit';

export async function GET({ params, platform }) {
  const { videoId, path } = params;
  const customerCode = platform.env.CLOUDFLARE_STREAM_CUSTOMER_CODE;
  const token = await platform.env.CLOUDFLARE_API_TOKEN.get();
  const accountId = platform.env.CF_ACCOUNT_ID;

  if (!customerCode) {
    return json({ error: 'Not configured' }, { status: 500 });
  }

  // Try generating a signed token (graceful fallback if no permission)
  let tokenParam = '';
  if (token && accountId) {
    try {
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
      if (tokenData.success && tokenData.result.token) {
        tokenParam = `?token=${tokenData.result.token}`;
      }
    } catch {
      // Signed token failed — try without it
    }
  }

  // Build upstream URL
  const upstreamUrl = `https://customer-${customerCode}.cloudflarestream.com/${videoId}/${path}${tokenParam}`;

  try {
    const upstreamRes = await fetch(upstreamUrl);

    if (!upstreamRes.ok) {
      return json({ error: `Upstream ${upstreamRes.status}`, url: path }, { status: upstreamRes.status });
    }

    const contentType = path.endsWith('.m3u8') ? 'application/vnd.apple.mpegurl'
      : path.endsWith('.ts') ? 'video/mp2t'
      : path.endsWith('.mp4') ? 'video/mp4'
      : path.endsWith('.m4s') ? 'video/mp4'
      : path.endsWith('.mpd') ? 'application/dash+xml'
      : path.endsWith('.jpg') ? 'image/jpeg'
      : upstreamRes.headers.get('content-type') || 'application/octet-stream';

    return new Response(upstreamRes.body, {
      status: 200,
      headers: {
        'Content-Type': contentType,
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET',
        'Access-Control-Allow-Headers': '*',
        'Cache-Control': 'public, max-age=3600'
      }
    });
  } catch (e) {
    return json({ error: e.message }, { status: 500 });
  }
}

// Handle CORS preflight
export async function OPTIONS() {
  return new Response(null, {
    status: 204,
    headers: {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET',
      'Access-Control-Allow-Headers': '*',
      'Access-Control-Max-Age': '86400'
    }
  });
}
