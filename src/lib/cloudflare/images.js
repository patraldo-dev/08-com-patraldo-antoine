import { CF_IMAGES_ACCOUNT_HASH } from '$lib/config.js';

/**
 * Cloudflare Images utility functions
 */

/**
 * Generate thumbnail URL - matches your working pattern exactly
 */
export function getThumbnailUrl(imageId) {
  // Your working pattern: https://imagedelivery.net/${hash}/${id}/thumbnail
  return imageId 
    ? `https://imagedelivery.net/${CF_IMAGES_ACCOUNT_HASH}/${imageId}/thumbnail`
    : '';
}

/**
 * Generate full artwork image URL
 */
export function getArtworkImageUrl(artwork) {
  // Match your working pattern
  return artwork.imageId
    ? `https://imagedelivery.net/${CF_IMAGES_ACCOUNT_HASH}/${artwork.imageId}/public`
    : '';
}

/**
 * Simple version for now
 */
export function getCloudflareImageUrl(imageId, options = {}) {
  return getThumbnailUrl(imageId);
}
