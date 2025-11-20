export async function load({ platform }) {
  try {
    const db = platform?.env?.ARTWORKS_DB;
    
    if (!db) {
      console.warn('DB not available');
      return { artworks: [], videos: [] };
    }

    // ... your existing query ...

    // Filter artworks that have videos
    const videos = artworks.filter(artwork => artwork.video_id);
    
    // Shuffle videos with daily seed
    const shuffledVideos = shuffleArray(videos);
    
    console.log(`Loaded ${shuffledVideos.length} videos for daily rotation`);
    
    return { 
      artworks: shuffledArtworks,
      videos: shuffledVideos
    };
    
  } catch (error) {
    console.error('Error loading artworks:', error);
    return { artworks: [], videos: [] };
  }
}
