import { getAllArtworksWithTransforms } from '$lib/db/artwork-transforms.js';

/**
 * Load artworks with transformations for 3D art manipulator
 * @type {import('./$types').PageServerLoad}
 */
export async function load({ platform }) {
  if (!platform?.env?.DB) {
    return { 
      artworks: [], 
      cloudflareAccountId: '',
      error: 'Database not available' 
    };
  }

  try {
    // Load all published artworks
    const artworks = await getAllArtworksWithTransforms(platform.env.DB, {
      published: true
    });
    
    return { 
      artworks,
      cloudflareAccountId: platform.env.CLOUDFLARE_ACCOUNT_ID || ''
    };
  } catch (error) {
    console.error('Load 3D art error:', error);
    return { 
      artworks: [], 
      cloudflareAccountId: '',
      error: error.message 
    };
  }
}
