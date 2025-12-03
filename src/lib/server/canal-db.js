// src/lib/server/canal-db.js
import { nanoid } from 'nanoid';

/**
 * @typedef {Object} ArtworkFilm
 * @property {string} id
 * @property {string} title_es
 * @property {string} title_en
 * @property {string} title_fr
 * @property {string} description_es
 * @property {string} description_en
 * @property {string} description_fr
 * @property {string} stream_video_id
 * @property {string} thumbnail_url
 * @property {number} duration
 * @property {number} is_featured
 * @property {number} created_at
 * @property {number} view_count
 * @property {number} artwork_id - Link to artwork in ARTWORKS_DB
 * @property {string} [image_id] - Original image_id from artwork
 */

/**
 * @typedef {Object} LocalizedFilm
 * @property {string} id
 * @property {string} title
 * @property {string} description
 * @property {string} stream_video_id
 * @property {string} thumbnail_url
 * @property {number} duration
 * @property {number} is_featured
 * @property {number} created_at
 * @property {number} view_count
 * @property {number} artwork_id
 * @property {Object} [artwork] - Optional linked artwork data
 */

/**
 * @typedef {Object} Artwork
 * @property {number} id
 * @property {string} title
 * @property {string} slug
 * @property {string} type
 * @property {string} image_id
 * @property {string} video_id
 * @property {string} description
 * @property {number} year
 * @property {boolean} featured
 * @property {boolean} published
 * @property {number} order_index
 * @property {string} created_at
 * @property {string} updated_at
 * @property {boolean} story_enabled
 * @property {string} story_intro
 * @property {string} display_name
 */

export class CanalDatabase {
  /**
   * @param {import('@cloudflare/workers-types').D1Database} artworksDb - antoine-artworks (primary)
   * @param {Object} options - Configuration options
   * @param {string} [options.cloudflareAccountHash] - For constructing image URLs
   * @param {string} [options.defaultCustomerCode] - Cloudflare Stream customer code
   */
  constructor(artworksDb, options = {}) {
    this.artworksDb = artworksDb;
    this.cloudflareAccountHash = options.cloudflareAccountHash || '';
    this.defaultCustomerCode = options.defaultCustomerCode || '';
  }

  /**
   * Convert Cloudflare Images image_id to full URL
   * @param {string} imageId
   * @param {string} [variant] - Image variant (default: 'public')
   * @returns {string}
   */
  imageIdToUrl(imageId, variant = 'public') {
    if (!imageId) return '';
    if (imageId.startsWith('http')) return imageId;
    if (!this.cloudflareAccountHash) return imageId; // Return as-is if no account hash
    return `https://imagedelivery.net/${this.cloudflareAccountHash}/${imageId}/${variant}`;
  }

  /**
   * Get featured film from artworks database
   * @param {Object} [options]
   * @param {boolean} [options.includeArtworkData] - Whether to include full artwork data
   * @returns {Promise<ArtworkFilm | null>}
   */
  async getFeaturedFilm(options = {}) {
    if (!this.artworksDb) {
      console.error('No artworks database available');
      return null;
    }

    try {
      const artwork = await this.artworksDb
        .prepare(`
          SELECT * FROM artworks 
          WHERE video_id IS NOT NULL 
            AND TRIM(video_id) != ''
            AND published = true
          ORDER BY 
            featured DESC, -- Featured artworks first
            created_at DESC 
          LIMIT 1
        `)
        .first();
      
      if (!artwork) {
        return null;
      }

      return await this.artworkToFilm(artwork, options);
      
    } catch (error) {
      console.error('Error fetching featured film from artworks:', error);
      return null;
    }
  }

  /**
   * Get film by artwork ID
   * @param {number} artworkId
   * @param {Object} [options]
   * @param {boolean} [options.includeArtworkData]
   * @returns {Promise<ArtworkFilm | null>}
   */
  async getFilmByArtworkId(artworkId, options = {}) {
    try {
      const artwork = await this.artworksDb
        .prepare('SELECT * FROM artworks WHERE id = ? AND published = true')
        .bind(artworkId)
        .first();
      
      if (!artwork || !artwork.video_id) {
        return null;
      }

      return await this.artworkToFilm(artwork, options);
    } catch (error) {
      console.error(`Error fetching film for artwork ${artworkId}:`, error);
      return null;
    }
  }

  /**
   * Get all films (artworks with videos)
   * @param {Object} [options]
   * @param {number} [options.limit] - Maximum number of films to return
   * @param {number} [options.offset] - Pagination offset
   * @param {boolean} [options.featuredOnly] - Only return featured artworks
   * @returns {Promise<ArtworkFilm[]>}
   */
  async getAllFilms(options = {}) {
    const { limit = 50, offset = 0, featuredOnly = false } = options;
    
    try {
      let query = `
        SELECT * FROM artworks 
        WHERE video_id IS NOT NULL 
          AND TRIM(video_id) != ''
          AND published = true
      `;
      
      if (featuredOnly) {
        query += ' AND featured = true';
      }
      
      query += ' ORDER BY created_at DESC LIMIT ? OFFSET ?';
      
      const result = await this.artworksDb
        .prepare(query)
        .bind(limit, offset)
        .all();
      
      const films = [];
      for (const artwork of result.results) {
        const film = await this.artworkToFilm(artwork);
        if (film) films.push(film);
      }
      
      return films;
    } catch (error) {
      console.error('Error fetching all films:', error);
      return [];
    }
  }

  /**
   * Convert artwork to film format
   * @param {Artwork} artwork
   * @param {Object} [options]
   * @param {boolean} [options.includeArtworkData]
   * @returns {Promise<ArtworkFilm>}
   */
  async artworkToFilm(artwork, options = {}) {
    const { includeArtworkData = false } = options;
    
    // Parse created_at timestamp
    let createdAt;
    try {
      createdAt = artwork.created_at ? Date.parse(artwork.created_at) : Date.now();
    } catch {
      createdAt = Date.now();
    }
    
    // Estimate duration based on artwork type or use default
    const duration = this.estimateDuration(artwork);
    
    const film = {
      id: `artwork-${artwork.id}`,
      title_es: artwork.title || 'Untitled',
      title_en: artwork.title || 'Untitled',
      title_fr: artwork.title || 'Untitled',
      description_es: artwork.description || '',
      description_en: artwork.description || '',
      description_fr: artwork.description || '',
      stream_video_id: artwork.video_id,
      thumbnail_url: this.imageIdToUrl(artwork.image_id),
      duration: duration,
      is_featured: artwork.featured ? 1 : 0,
      created_at: createdAt,
      view_count: 0, // Could be tracked separately if needed
      artwork_id: artwork.id,
      image_id: artwork.image_id || '' // Keep original for reference
    };
    
    // Include full artwork data if requested
    if (includeArtworkData) {
      film.artwork = artwork;
    }
    
    return film;
  }

  /**
   * Estimate video duration based on artwork type
   * @param {Artwork} artwork
   * @returns {number} Duration in seconds
   */
  estimateDuration(artwork) {
    // Default durations based on artwork type
    const durationMap = {
      'video': 180, // 3 minutes for regular videos
      'short-film': 600, // 10 minutes for short films
      'animation': 120, // 2 minutes for animations
      'performance': 300, // 5 minutes for performances
      'documentation': 240 // 4 minutes for documentation
    };
    
    return durationMap[artwork.type?.toLowerCase()] || 180; // Default 3 minutes
  }

  /**
   * Get localized film data
   * @param {ArtworkFilm} film
   * @param {string} locale - es, en, fr (or es-MX, en-US, fr-CA)
   * @param {Object} [options]
   * @param {boolean} [options.includeArtworkData] - Fetch and include full artwork
   * @returns {Promise<LocalizedFilm>}
   */
  async getLocalizedFilm(film, locale = 'es', options = {}) {
    if (!film) {
      throw new Error('No film provided for localization');
    }
    
    const { includeArtworkData = false } = options;
    const lang = locale.split('-')[0];
    const supportedLangs = ['es', 'en', 'fr'];
    const actualLang = supportedLangs.includes(lang) ? lang : 'es';
    
    const localizedFilm = {
      id: film.id,
      title: film[`title_${actualLang}`] || film.title_es || 'Untitled',
      description: film[`description_${actualLang}`] || film.description_es || '',
      stream_video_id: film.stream_video_id,
      thumbnail_url: film.thumbnail_url,
      duration: film.duration || 0,
      is_featured: film.is_featured || 0,
      created_at: film.created_at,
      view_count: film.view_count || 0,
      artwork_id: film.artwork_id,
      image_id: film.image_id
    };

    // Fetch and include artwork data if requested
    if (includeArtworkData && film.artwork_id && this.artworksDb) {
      try {
        const artwork = await this.artworksDb
          .prepare('SELECT * FROM artworks WHERE id = ?')
          .bind(film.artwork_id)
          .first();
        
        if (artwork) {
          localizedFilm.artwork = artwork;
        }
      } catch (err) {
        console.error('Failed to fetch linked artwork:', err);
      }
    }

    return localizedFilm;
  }

  /**
   * Increment view count for a film (stored separately if needed)
   * @param {string} filmId
   * @returns {Promise<void>}
   */
  async incrementViewCount(filmId) {
    // Since we don't have a films table, you could:
    // 1. Create a view_counts table
    // 2. Use analytics service
    // 3. Log to console for now
    console.log(`View incremented for film: ${filmId}`);
    
    // Example of creating a view_counts table:
    /*
    await this.artworksDb
      .prepare(`
        CREATE TABLE IF NOT EXISTS view_counts (
          id TEXT PRIMARY KEY,
          film_id TEXT NOT NULL,
          view_count INTEGER DEFAULT 0,
          last_viewed TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
      `)
      .run();
    
    await this.artworksDb
      .prepare(`
        INSERT INTO view_counts (id, film_id, view_count) 
        VALUES (?, ?, 1)
        ON CONFLICT(id) DO UPDATE SET 
          view_count = view_count + 1,
          last_viewed = CURRENT_TIMESTAMP
      `)
      .bind(`view-${filmId}`, filmId)
      .run();
    */
  }

  /**
   * Record watch history (stub - implement if needed)
   * @param {string} userId
   * @param {string} filmId
   * @param {number} progress
   * @returns {Promise<void>}
   */
  async recordWatchHistory(userId, filmId, progress) {
    console.log(`Watch history: user ${userId}, film ${filmId}, progress ${progress}%`);
    // Implement if you add user accounts and want to track watch history
  }

  /**
   * Get user watch history (stub - implement if needed)
   * @param {string} userId
   * @param {number} limit
   * @returns {Promise<any[]>}
   */
  async getUserWatchHistory(userId, limit = 20) {
    console.log(`Getting watch history for user ${userId}`);
    return []; // Implement if needed
  }

  /**
   * Search films by title or description
   * @param {string} query
   * @param {Object} [options]
   * @returns {Promise<ArtworkFilm[]>}
   */
  async searchFilms(query, options = {}) {
    const { limit = 20 } = options;
    
    if (!query?.trim()) {
      return this.getAllFilms({ limit });
    }
    
    try {
      const searchTerm = `%${query}%`;
      const result = await this.artworksDb
        .prepare(`
          SELECT * FROM artworks 
          WHERE (title LIKE ? OR description LIKE ?)
            AND video_id IS NOT NULL 
            AND TRIM(video_id) != ''
            AND published = true
          ORDER BY created_at DESC 
          LIMIT ?
        `)
        .bind(searchTerm, searchTerm, limit)
        .all();
      
      const films = [];
      for (const artwork of result.results) {
        const film = await this.artworkToFilm(artwork);
        if (film) films.push(film);
      }
      
      return films;
    } catch (error) {
      console.error('Error searching films:', error);
      return [];
    }
  }

  /**
   * Get films by artwork type
   * @param {string} type
   * @param {Object} [options]
   * @returns {Promise<ArtworkFilm[]>}
   */
  async getFilmsByType(type, options = {}) {
    const { limit = 50 } = options;
    
    try {
      const result = await this.artworksDb
        .prepare(`
          SELECT * FROM artworks 
          WHERE type = ? 
            AND video_id IS NOT NULL 
            AND TRIM(video_id) != ''
            AND published = true
          ORDER BY created_at DESC 
          LIMIT ?
        `)
        .bind(type, limit)
        .all();
      
      const films = [];
      for (const artwork of result.results) {
        const film = await this.artworkToFilm(artwork);
        if (film) films.push(film);
      }
      
      return films;
    } catch (error) {
      console.error(`Error fetching films by type ${type}:`, error);
      return [];
    }
  }
}
