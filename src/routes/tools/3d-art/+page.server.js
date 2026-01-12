import { getAllArtworksWithTransforms } from '$lib/db/artwork-transforms.js';

/**
 * Load artworks with transformations for 3D art manipulator
 * @type {import('./$types').PageServerLoad}
 */
export async function load({ platform }) {
  console.log('Loading 3D art page...');
  
  const db = platform?.env?.ARTWORKS_DB;
  
  if (!db) {
    console.error('ARTWORKS_DB not available in platform.env');
    console.log('Available env keys:', platform.env ? Object.keys(platform.env) : 'No env object');
    return { 
      artworks: [], 
      cloudflareAccountId: '',
      error: 'Database not available' 
    };
  }

  try {
    console.log('Fetching artworks from ARTWORKS_DB...');
    const artworks = await getAllArtworksWithTransforms(db, {
      published: true
    });
    
    console.log('Artworks loaded:', artworks.length);
    
    return { 
      artworks,
      cloudflareAccountId: '' // Will get from config in component
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
