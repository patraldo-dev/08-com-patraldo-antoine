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
    const res = await fetch(
      `https://api.cloudflare.com/client/v4/accounts/${accountId}/stream/${videoId}`,
      { headers: { Authorization: `Bearer ${token}` } }
    );
    const data = await res.json();

    if (!data.success) {
      return json({ error: 'Video not found', details: data.errors }, { status: 404 });
    }

    const video = data.result;

    return json({
      uid: video.uid,
      status: video.status,
      duration: video.duration,
      streamUrl: `https://customer-${customerCode}.cloudflarestream.com/${video.uid}/manifest/video.m3u8`,
      // Direct video URL (works without HLS)
      videoUrl: `https://customer-${customerCode}.cloudflarestream.com/${video.uid}/downloads/default.mp4`,
      thumbnail: video.thumbnail,
      aspectRatio: video.meta?.aspect_ratio || video.aspectRatio || '16:9'
    });
  } catch (e) {
    return json({ error: e.message }, { status: 500 });
  }
}
