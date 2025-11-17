// Add after the localStorage operations in trackVisit():
export async function trackVisit(artworkId, metadata = {}) {
  // ... existing code ...
  
  // Send to analytics API
  try {
    await fetch('/api/analytics', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        eventType: 'visit',
        artworkId,
        metadata
      })
    });
  } catch (error) {
    console.error('Analytics tracking failed:', error);
  }
  
  return visits[artworkId];
}

// Add similar tracking to toggleFavorite():
export function toggleFavorite(artworkId) {
  // ... existing code ...
  
  const isFav = favorites.has(artworkId.toString());
  
  // Send to analytics API
  try {
    fetch('/api/analytics', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        eventType: isFav ? 'favorite' : 'unfavorite',
        artworkId
      })
    });
  } catch (error) {
    console.error('Analytics tracking failed:', error);
  }
  
  return isFav;
}
