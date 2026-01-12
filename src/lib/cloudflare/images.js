import { CF_IMAGES_ACCOUNT_HASH } from '$lib/config.js';

export function getCloudflareImageUrl(imageId, options = {}) {
  const baseUrl = `https://imagedelivery.net/${CF_IMAGES_ACCOUNT_HASH}/${imageId}`;
  
  if (Object.keys(options).length === 0) return baseUrl;

  const params = new URLSearchParams();
  if (options.width) params.append('w', options.width.toString());
  if (options.height) params.append('h', options.height.toString());
  if (options.format) params.append('format', options.format);
  if (options.quality) params.append('q', options.quality.toString());
  if (options.fit) params.append('fit', options.fit);

  return `${baseUrl}/public?${params.toString()}`;
}

export function getThumbnailUrl(imageId, size = 400) {
  return getCloudflareImageUrl(imageId, {
    width: size,
    height: size,
    format: 'webp',
    quality: 80,
    fit: 'cover'
  });
}

export function getArtworkImageUrl(artwork) {
  const options = {
    format: 'webp',
    quality: 90
  };

  if (artwork.type === 'video' || artwork.type === 'animation') {
    options.width = 1920;
  } else if (artwork.isCinematic) {
    options.width = 1600;
  } else {
    options.width = 1200;
  }

  return getCloudflareImageUrl(artwork.imageId, options);
}
