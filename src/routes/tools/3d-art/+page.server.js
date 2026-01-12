import { getAllArtworksWithTransforms } from '$lib/db/artwork-transforms.js';

export async function load({ platform }) {
  const db = platform?.env?.ARTWORKS_DB;
  
  if (!db) {
    console.error('ARTWORKS_DB not available');
    return { artworks: [] };
  }

  try {
    const artworks = await getAllArtworksWithTransforms(db, {
      published: true
    });
    
    return { artworks };
  } catch (error) {
    console.error('Error loading artworks:', error);
    return { artworks: [] };
  }
}
