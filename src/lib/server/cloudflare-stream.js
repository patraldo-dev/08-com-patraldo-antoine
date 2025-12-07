// src/lib/server/cloudflare-stream.js

/**
 * Get video details from Cloudflare Stream
 * @param {string} videoId
 * @param {string} accountId
 * @param {string} apiKey
 * @returns {Promise<Object>}
 */
export async function getStreamVideoDetails(videoId, accountId, apiKey) {
  try {
    const response = await fetch(
      `https://api.cloudflare.com/client/v4/accounts/${accountId}/stream/${videoId}`,
      {
        headers: {
          'Authorization': `Bearer ${apiKey}`,
          'Content-Type': 'application/json'
        }
      }
    );

    if (!response.ok) {
      throw new Error(`Stream API error: ${response.status}`);
    }

    const data = await response.json();
    
    return {
      duration: data.result?.duration || 0,
      width: data.result?.input?.width || 0,
      height: data.result?.input?.height || 0,
      status: data.result?.status
    };
  } catch (err) {
    console.error('Failed to fetch Stream video details:', err);
    return null;
  }
}
