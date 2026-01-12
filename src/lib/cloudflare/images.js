import { CF_IMAGES_ACCOUNT_HASH } from '$lib/config.js';

/**
 * Cloudflare Images utility functions
 * Handles image URL generation and transformations
 */

/**
 * Generate Cloudflare Images URL with transformations
 * @param {string} imageId - The image ID from your database
 * @param {Object} [options] - Transformation options
 * @param {number} [options.width] - Target width in pixels
 * @param {number} [options.height] - Target height in pixels
 * @param {string} [options.format] - Format (webp, jpeg, png, avif)
 * @param {number} [options.quality] - Quality (1-100)
 * @param {string} [options.fit] - Fit mode (scale-down, contain, cover, crop, pad)
 * @returns {string} The transformed image URL
 */
export function getCloudflareImageUrl(imageId, options = {}) {
  const baseUrl = `https://imagedelivery.net/${CF_IMAGES_ACCOUNT_HASH}/${imageId}`;

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
 * Get thumbnail image for artwork
 * @param {string} imageId - The image ID
 * @param {number} [size=400] - Thumbnail size
 * @returns {string} Thumbnail image URL
 */
export function getThumbnailUrl(imageId, size = 400) {
  return getCloudflareImageUrl(imageId, {
    width: size,
    height: size,
    format: 'webp',
    quality: 80,
    fit: 'cover'
  });
}

/**
 * Get full-size artwork image
 * @param {Object} artwork - Artwork object
 * @returns {string} Full-size image URL
 */
export function getArtworkImageUrl(artwork) {
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

  return getCloudflareImageUrl(artwork.imageId, options);
}

/**
 * Get responsive image URLs for different screen sizes
 * @param {string} imageId - The image ID
 * @param {Object} [options] - Base transformation options
 * @returns {Object} Object with image URLs for different breakpoints
 */
export function getResponsiveImageUrls(imageId, options = {}) {
  return {
    sm: getCloudflareImageUrl(imageId, { ...options, width: 640 }),
    md: getCloudflareImageUrl(imageId, { ...options, width: 768 }),
    lg: getCloudflareImageUrl(imageId, { ...options, width: 1024 }),
    xl: getCloudflareImageUrl(imageId, { ...options, width: 1280 }),
    '2xl': getCloudflareImageUrl(imageId, { ...options, width: 1536 }),
    full: getCloudflareImageUrl(imageId, { ...options, width: 1920 })
  };
}
