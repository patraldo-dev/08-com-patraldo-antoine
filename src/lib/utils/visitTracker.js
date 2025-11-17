// src/lib/utils/visitTracker.js
const STORAGE_KEY = 'artwork_visits';
const FAVORITES_KEY = 'artwork_favorites';

export function getAllVisits() {
  if (typeof window === 'undefined') return {};
  
  try {
    const data = localStorage.getItem(STORAGE_KEY);
    return data ? JSON.parse(data) : {};
  } catch (error) {
    console.error('Error reading visits:', error);
    return {};
  }
}

// Alias getVisitedArtworks to getAllVisits to fulfill import contract
export function getVisitedArtworks() {
  return getAllVisits();
}

export function trackVisit(artworkId, metadata = {}) {
  if (typeof window === 'undefined') return null;
  
  try {
    const visits = getAllVisits();
    const now = new Date().toISOString();
    
    if (visits[artworkId]) {
      visits[artworkId].lastVisited = now;
      visits[artworkId].viewCount = (visits[artworkId].viewCount || 0) + 1;
      visits[artworkId].metadata = { ...visits[artworkId].metadata, ...metadata };
    } else {
      visits[artworkId] = {
        firstVisited: now,
        lastVisited: now,
        viewCount: 1,
        metadata
      };
    }
    
    localStorage.setItem(STORAGE_KEY, JSON.stringify(visits));
    
    window.dispatchEvent(new CustomEvent('artworkVisited', { 
      detail: { artworkId, visit: visits[artworkId] }
    }));
    
    // Send to analytics API (don't await - fire and forget)
    sendAnalytics('visit', artworkId, metadata).catch(err => 
      console.error('Analytics tracking failed:', err)
    );
    
    return visits[artworkId];
  } catch (error) {
    console.error('Error tracking visit:', error);
    return null;
  }
}

export function hasVisited(artworkId) {
  const visits = getAllVisits();
  return !!visits[artworkId];
}

export function getVisit(artworkId) {
  const visits = getAllVisits();
  return visits[artworkId] || null;
}

export function getAllFavorites() {
  if (typeof window === 'undefined') return new Set();
  
  try {
    const data = localStorage.getItem(FAVORITES_KEY);
    return new Set(data ? JSON.parse(data) : []);
  } catch (error) {
    console.error('Error reading favorites:', error);
    return new Set();
  }
}

export function toggleFavorite(artworkId) {
  if (typeof window === 'undefined') return false;
  
  try {
    const favorites = getAllFavorites();
    const wasFavorite = favorites.has(artworkId.toString());
    
    if (wasFavorite) {
      favorites.delete(artworkId.toString());
    } else {
      favorites.add(artworkId.toString());
    }
    
    localStorage.setItem(FAVORITES_KEY, JSON.stringify([...favorites]));
    
    const isFavorite = favorites.has(artworkId.toString());
    
    window.dispatchEvent(new CustomEvent('favoriteToggled', { 
      detail: { artworkId, isFavorite }
    }));
    
    // Send to analytics API (don't await - fire and forget)
    sendAnalytics(isFavorite ? 'favorite' : 'unfavorite', artworkId).catch(err => 
      console.error('Analytics tracking failed:', err)
    );
    
    return isFavorite;
  } catch (error) {
    console.error('Error toggling favorite:', error);
    return false;
  }
}

export function isFavorite(artworkId) {
  const favorites = getAllFavorites();
  return favorites.has(artworkId.toString());
}

export function getVisitStats() {
  const visits = getAllVisits();
  const artworkIds = Object.keys(visits);
  
  return {
    totalArtworks: artworkIds.length,
    totalViews: artworkIds.reduce((sum, id) => sum + (visits[id].viewCount || 0), 0),
    favorites: getAllFavorites().size,
    mostViewed: artworkIds
      .sort((a, b) => (visits[b].viewCount || 0) - (visits[a].viewCount || 0))
      .slice(0, 5)
      .map(id => ({ id, ...visits[id] })),
    recentlyViewed: artworkIds
      .sort((a, b) => new Date(visits[b].lastVisited) - new Date(visits[a].lastVisited))
      .slice(0, 10)
      .map(id => ({ id, ...visits[id] }))
  };
}

export function clearAllVisits() {
  if (typeof window === 'undefined') return;
  
  localStorage.removeItem(STORAGE_KEY);
  window.dispatchEvent(new CustomEvent('visitsCleared'));
}

export function exportVisitData() {
  const visits = getAllVisits();
  const favorites = [...getAllFavorites()];
  
  return JSON.stringify({
    visits,
    favorites,
    exportedAt: new Date().toISOString()
  }, null, 2);
}

export function importVisitData(jsonData) {
  if (typeof window === 'undefined') return false;
  
  try {
    const data = JSON.parse(jsonData);
    
    if (data.visits) {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(data.visits));
    }
    
    if (data.favorites) {
      localStorage.setItem(FAVORITES_KEY, JSON.stringify(data.favorites));
    }
    
    window.dispatchEvent(new CustomEvent('visitsImported'));
    return true;
  } catch (error) {
    console.error('Error importing data:', error);
    return false;
  }
}

// ANALYTICS HELPER FUNCTION
async function sendAnalytics(eventType, artworkId, metadata = {}) {
  if (typeof window === 'undefined') return;
  
  try {
    await fetch('/api/analytics', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        eventType,
        artworkId,
        metadata
      })
    });
  } catch (error) {
    // Fail silently - analytics shouldn't break user experience
    console.debug('Analytics send failed (non-critical):', error);
  }
}
