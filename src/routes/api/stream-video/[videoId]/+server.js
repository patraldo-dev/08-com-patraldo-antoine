import { json } from '@sveltejs/kit';

export async function GET({ params, platform }) {
  const { videoId } = params;
  const token = await platform.env.CLOUDFLARE_API_TOKEN.get();
  const accountId = platform.env.CF_ACCOUNT_ID;
  const customerCode = platform.env.CLOUDFLARE_STREAM_CUSTOMER_CODE;

  if (!token || !accountId || !customerCode) {
    return json({ error: 'Stream not configured' }, { status: 500 });
  }

  try {
    // 1. Get video info
    const res = await fetch(
      `https://api.cloudflare.com/client/v4/accounts/${accountId}/stream/${videoId}`,
      { headers: { Authorization: `Bearer ${token}` } }
    );
    const data = await res.json();

    if (!data.success) {
      return json({ error: 'Video not found', details: data.errors }, { status: 404 });
    }

    const video = data.result;

    // 2. Generate signed URL token (valid 1 hour)
    const tokenRes = await fetch(
      `https://api.cloudflare.com/client/v4/accounts/${accountId}/stream/${videoId}/token`,
      {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${token}`,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          maxAgeSeconds: 3600
        })
      }
    );
    const tokenData = await tokenRes.json();
    const signedToken = tokenData.success ? tokenData.result.token : null;

    // 3. Build direct video URL with signed token
    const videoUrl = signedToken
      ? `https://customer-${customerCode}.cloudflarestream.com/${video.uid}/downloads/default.mp4?token=${signedToken}`
      : null;

    return json({
      uid: video.uid,
      status: video.status,
      duration: video.duration,
      streamUrl: `https://customer-${customerCode}.cloudflarestream.com/${video.uid}/manifest/video.m3u8`,
      videoUrl,
      thumbnail: video.thumbnail,
      aspectRatio: video.meta?.aspect_ratio || video.aspectRatio || '16:9'
    });
  } catch (e) {
    return json({ error: e.message }, { status: 500 });
  }
}
