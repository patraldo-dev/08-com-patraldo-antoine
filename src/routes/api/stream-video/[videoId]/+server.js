import { json } from '@sveltejs/kit';

export async function GET({ params, platform }) {
  const { videoId } = params;
  const token = await platform.env.CLOUDFLARE_API_TOKEN.get();
  const customerCode = platform.env.CLOUDFLARE_STREAM_CUSTOMER_CODE;

  if (!token || !customerCode) {
    return json({ error: 'Stream not configured' }, { status: 500 });
  }

  try {
    const res = await fetch(
      `https://api.cloudflare.com/client/v4/accounts/${customerCode}/stream/${videoId}`,
      { headers: { Authorization: `Bearer ${token}` } }
    );
    const data = await res.json();

    if (!data.success) {
      return json({ error: 'Video not found' }, { status: 404 });
    }

    const video = data.result;
    // CF Stream provides direct download URL in the result
    const mp4Url = video.download?.url || video.preview;

    return json({
      uid: video.uid,
      status: video.status,
      duration: video.duration,
      // Use the Stream direct playback URL (HLS manifest or direct MP4)
      // For VideoTexture we need direct MP4 - use the download URL or signed token
      streamUrl: `https://customer-${customerCode}.cloudflarestream.com/${video.uid}/manifest/video.m3u8`,
      // Direct MP4 for Three.js VideoTexture
      mp4Url: mp4Url || `https://customer-${customerCode}.cloudflarestream.com/${video.uid}/downloads/default.mp4`,
      thumbnail: video.thumbnail,
      aspectRatio: video.meta?.aspect_ratio || video.aspectRatio
    });
  } catch (e) {
    return json({ error: e.message }, { status: 500 });
  }
}
