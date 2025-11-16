// src/lib/utils/visitTracker.js
/**
 * Track artwork visits in localStorage
 */
const STORAGE_KEY = 'artwork_visits';
const FAVORITES_KEY = 'artwork_favorites';

/**
 * Get all visit data
 * @returns {Object} Visit data keyed by artwork ID
 */
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

/**
 * Track a visit to an artwork
 * @param {number|string} artworkId - The artwork ID
 * @param {Object} metadata - Optional metadata (title, image, etc.)
 */
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
    
    return visits[artworkId];
  } catch (error) {
    console.error('Error tracking visit:', error);
    return null;
  }
}

/**
 * Check if an artwork has been visited
 * @param {number|string} artworkId 
 * @returns {boolean}
 */
export function hasVisited(artworkId) {
  const visits = getAllVisits();
  return !!visits[artworkId];
}

/**
 * Get visit data for specific artwork
 * @param {number|string} artworkId 
 * @returns {Object|null}
 */
export function getVisit(artworkId) {
  const visits = getAllVisits();
  return visits[artworkId] || null;
}

/**
 * Get all favorites
 * @returns {Set} Set of favorited artwork IDs
 */
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

/**
 * Toggle favorite status
 * @param {number|string} artworkId 
 * @returns {boolean} New favorite status
 */
export function toggleFavorite(artworkId) {
  if (typeof window === 'undefined') return false;
  
  try {
    const favorites = getAllFavorites();
    
    if (favorites.has(artworkId.toString())) {
      favorites.delete(artworkId.toString());
    } else {
      favorites.add(artworkId.toString());
    }
    
    localStorage.setItem(FAVORITES_KEY, JSON.stringify([...favorites]));
    
    window.dispatchEvent(new CustomEvent('favoriteToggled', { 
      detail: { artworkId, isFavorite: favorites.has(artworkId.toString()) }
    }));
    
    return favorites.has(artworkId.toString());
  } catch (error) {
    console.error('Error toggling favorite:', error);
    return false;
  }
}

/**
 * Check if artwork is favorited
 * @param {number|string} artworkId 
 * @returns {boolean}
 */
export function isFavorite(artworkId) {
  const favorites = getAllFavorites();
  return favorites.has(artworkId.toString());
}

/**
 * Get visit statistics
 * @returns {Object} Statistics about visits
 */
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

/**
 * Clear all visit data
 */
export function clearAllVisits() {
  if (typeof window === 'undefined') return;
  
  localStorage.removeItem(STORAGE_KEY);
  window.dispatchEvent(new CustomEvent('visitsCleared'));
}

/**
 * Export visit data as JSON
 * @returns {string} JSON string of all data
 */
export function exportVisitData() {
  const visits = getAllVisits();
  const favorites = [...getAllFavorites()];
  
  return JSON.stringify({
    visits,
    favorites,
    exportedAt: new Date().toISOString()
  }, null, 2);
}

/**
 * Import visit data from JSON
 * @param {string} jsonData - JSON string to import
 * @returns {boolean} Success status
 */
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
