/**
 * Cloudflare Images utility functions
 * Handles image URL generation and transformations
 */

/**
 * Generate Cloudflare Images URL with transformations
 * @param {Object} env - Environment bindings
 * @param {string} env.CLOUDFLARE_ACCOUNT_ID - Cloudflare account ID
 * @param {string} imageId - The image ID from your database
 * @param {Object} [options] - Transformation options
 * @param {number} [options.width] - Target width in pixels
 * @param {number} [options.height] - Target height in pixels
 * @param {string} [options.format] - Format (webp, jpeg, png, avif)
 * @param {number} [options.quality] - Quality (1-100)
 * @param {string} [options.fit] - Fit mode (scale-down, contain, cover, crop, pad)
 * @returns {string} The transformed image URL
 */
export function getCloudflareImageUrl(env, imageId, options = {}) {
  const baseUrl = `https://imagedelivery.net/${env.CLOUDFLARE_ACCOUNT_ID}/${imageId}`;

  // Return base URL if no options provided
  if (Object.keys(options).length === 0) return baseUrl;

  const params = new URLSearchParams();
  
  if (options.width) params.append('w', options.width.toString());
  if (options.height) params.append('h', options.height.toString());
  if (options.format) params.append('format', options.format);
  if (options.quality) params.append('q', options.quality.toString());
  if (options.fit) params.append('fit', options.fit);

  return `${baseUrl}/public?${params.toString()}`;
}

/**
 * Generate responsive image URLs for different screen sizes
 * @param {Object} env - Environment bindings
 * @param {string} imageId - The image ID from your database
 * @param {Object} [options] - Base transformation options
 * @returns {Object} Object with image URLs for different breakpoints
 */
export function getResponsiveImageUrls(env, imageId, options = {}) {
  return {
    sm: getCloudflareImageUrl(env, imageId, { ...options, width: 640 }),
    md: getCloudflareImageUrl(env, imageId, { ...options, width: 768 }),
    lg: getCloudflareImageUrl(env, imageId, { ...options, width: 1024 }),
    xl: getCloudflareImageUrl(env, imageId, { ...options, width: 1280 }),
    '2xl': getCloudflareImageUrl(env, imageId, { ...options, width: 1536 }),
    full: getCloudflareImageUrl(env, imageId, { ...options, width: 1920 })
  };
}

/**
 * Upload file to Cloudflare Images
 * @param {Object} env - Environment bindings
 * @param {string} env.CLOUDFLARE_ACCOUNT_ID - Cloudflare account ID
 * @param {string} env.CLOUDFLARE_API_TOKEN - Cloudflare API token
 * @param {File|Blob} file - The file to upload
 * @param {Object} [metadata] - Optional metadata to attach
 * @returns {Promise<Object>} Upload result with URLs and image ID
 */
export async function uploadToCloudflareImages(env, file, metadata = {}) {
  const formData = new FormData();
  formData.append('file', file);
  
  // Add metadata if provided
  if (Object.keys(metadata).length > 0) {
    formData.append('metadata', JSON.stringify(metadata));
  }

  const response = await fetch(
    `https://api.cloudflare.com/client/v4/accounts/${env.CLOUDFLARE_ACCOUNT_ID}/images/v1`,
    {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${env.CLOUDFLARE_API_TOKEN}`
      },
      body: formData
    }
  );

  const data = await response.json();

  if (!data.success) {
    const errorMessage = data.errors?.[0]?.message || 'Upload failed';
    throw new Error(errorMessage);
  }

  return {
    id: data.result.id,
    variants: data.result.variants,
    uploadUrl: data.result.variants[0],
    filename: data.result.filename
  };
}

/**
 * Extract image ID from Cloudflare Image URL
 * @param {string} url - The Cloudflare image URL
 * @returns {string|null} The image ID or null if not found
 */
export function extractImageId(url) {
  // Pattern: https://imagedelivery.net/{account_id}/{image_id}/...
  const match = url.match(/imagedelivery\.net\/[^\/]+\/([^\/]+)/);
  return match ? match[1] : null;
}

/**
 * Get optimized image for artwork type
 * @param {Object} env - Environment bindings
 * @param {Object} artwork - Artwork object with imageId
 * @returns {string} Optimized image URL
 */
export function getArtworkImageUrl(env, artwork) {
  const options = {
    format: 'webp',
    quality: 90
  };

  // Adjust based on artwork type
  if (artwork.type === 'video' || artwork.type === 'animation') {
    options.width = 1920;
  } else if (artwork.isCinematic) {
    options.width = 1600;
  } else {
    options.width = 1200;
  }

  return getCloudflareImageUrl(env, artwork.imageId, options);
}

/**
 * Get thumbnail image for artwork
 * @param {Object} env - Environment bindings
 * @param {string} imageId - The image ID
 * @param {number} [size=400] - Thumbnail size
 * @returns {string} Thumbnail image URL
 */
export function getThumbnailUrl(env, imageId, size = 400) {
  return getCloudflareImageUrl(env, imageId, {
    width: size,
    height: size,
    format: 'webp',
    quality: 80,
    fit: 'cover'
  });
}
