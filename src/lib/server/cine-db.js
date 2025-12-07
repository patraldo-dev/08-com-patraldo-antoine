// src/lib/server/cine-db.js

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
 * @property {boolean} story_enabled
 * @property {string} story_intro
 * @property {string} display_name
 * @property {boolean} is_cinematic
 * @property {string} aspect_ratio
 * @property {number} duration
 * @property {number} view_count
 */

export class CineDatabase {
  /**
   * @param {import('@cloudflare/workers-types').D1Database} artworksDb
   * @param {string} [cloudflareAccountHash]
   */
  constructor(artworksDb, cloudflareAccountHash = '') {
    this.db = artworksDb;
    this.cloudflareAccountHash = cloudflareAccountHash;
  }

  /**
   * Get featured cinematic artwork (16:9, is_cinematic = 1)
   * @returns {Promise<Artwork | null>}
   */
  async getFeaturedCinematic() {
    return await this.db
      .prepare(
        `SELECT * FROM artworks 
         WHERE video_id IS NOT NULL 
         AND is_cinematic = 1
         AND aspect_ratio = '16:9'
         AND published = 1 
         AND featured = 1 
         ORDER BY order_index DESC, created_at DESC 
         LIMIT 1`
      )
      .first();
  }

  /**
   * Get cinematic artwork by ID
   * @param {number} id
   * @returns {Promise<Artwork | null>}
   */
  async getCinematicById(id) {
    return await this.db
      .prepare(
        `SELECT * FROM artworks 
         WHERE id = ? 
         AND video_id IS NOT NULL
         AND is_cinematic = 1
         AND aspect_ratio = '16:9'`
      )
      .bind(id)
      .first();
  }

  /**
   * Get all cinematic artworks (16:9, is_cinematic = 1)
   * @param {Object} options
   * @param {number} [options.limit]
   * @param {string} [options.type]
   * @returns {Promise<Artwork[]>}
   */
  async getAllCinematics(options = {}) {
    const { limit = 100, type = null } = options;
    
    let query = `SELECT * FROM artworks 
                 WHERE video_id IS NOT NULL 
                 AND is_cinematic = 1
                 AND aspect_ratio = '16:9'
                 AND published = 1`;
    const params = [];
    
    if (type) {
      query += ' AND type = ?';
      params.push(type);
    }
    
    query += ' ORDER BY order_index DESC, created_at DESC LIMIT ?';
    params.push(limit);
    
    const result = await this.db
      .prepare(query)
      .bind(...params)
      .all();
    
    return result.results;
  }

  /**
   * Get related cinematics (same type, 16:9)
   * @param {string} type
   * @param {number} excludeId
   * @param {number} limit
   * @returns {Promise<Artwork[]>}
   */
  async getRelatedCinematics(type, excludeId, limit = 6) {
    const result = await this.db
      .prepare(
        `SELECT * FROM artworks 
         WHERE video_id IS NOT NULL 
         AND is_cinematic = 1
         AND aspect_ratio = '16:9'
         AND published = 1 
         AND type = ? 
         AND id != ? 
         ORDER BY order_index DESC 
         LIMIT ?`
      )
      .bind(type, excludeId, limit)
      .all();
    
    return result.results;
  }

  /**
   * Get daily rotation video (short clips only, is_cinematic = 0)
   * For use in #about-detail modal
   * @returns {Promise<Artwork | null>}
   */
  async getDailyVideo() {
    const today = new Date().toISOString().split('T')[0];
    const seed = parseInt(today.split('-').join(''));
    
    return await this.db
      .prepare(
        `SELECT * FROM artworks 
         WHERE video_id IS NOT NULL 
         AND (is_cinematic = 0 OR is_cinematic IS NULL)
         AND published = 1 
         ORDER BY (id * ?) % 1000
         LIMIT 1`
      )
      .bind(seed)
      .first();
  }

  /**
   * Increment view count for an artwork
   * @param {number} artworkId
   * @returns {Promise<void>}
   */
  async incrementViewCount(artworkId) {
    try {
      await this.db
        .prepare('UPDATE artworks SET view_count = COALESCE(view_count, 0) + 1 WHERE id = ?')
        .bind(artworkId)
        .run();
    } catch (err) {
      console.error('Failed to increment view count:', err);
    }
  }

  /**
   * Get video details from Cloudflare Stream API
   * @param {string} videoId
   * @param {string} accountId
   * @param {string} apiKey
   * @returns {Promise<Object|null>}
   */
  async getStreamVideoDetails(videoId, accountId, apiKey) {
    try {
      const response = await fetch(
        `https://api.cloudflare.com/client/v4/accounts/${accountId}/stream/${videoId}`,
        {
          headers: {
            'Authorization': `Bearer ${apiKey}`,
            'Content-Type': 'application/json'
          }
        }
      );

      if (!response.ok) {
        console.error(`Stream API error: ${response.status}`);
        return null;
      }

      const data = await response.json();
      
      return {
        duration: data.result?.duration || 0,
        width: data.result?.input?.width || 0,
        height: data.result?.input?.height || 0,
        status: data.result?.status,
        aspect_ratio: this.calculateAspectRatio(
          data.result?.input?.width,
          data.result?.input?.height
        )
      };
    } catch (err) {
      console.error('Failed to fetch Stream video details:', err);
      return null;
    }
  }

  /**
   * Calculate aspect ratio from width and height
   * @param {number} width
   * @param {number} height
   * @returns {string}
   */
  calculateAspectRatio(width, height) {
    if (!width || !height) return '16:9';
    
    const ratio = width / height;
    
    if (Math.abs(ratio - 16/9) < 0.1) return '16:9';
    if (Math.abs(ratio - 9/16) < 0.1) return '9:16';
    if (Math.abs(ratio - 4/3) < 0.1) return '4:3';
    if (Math.abs(ratio - 1) < 0.1) return '1:1';
    
    return '16:9'; // Default
  }

  /**
   * Get or fetch video duration from Cloudflare Stream
   * Caches result in database
   * @param {string} videoId
   * @param {number} artworkId
   * @param {string} accountId
   * @param {string} apiKey
   * @returns {Promise<number>}
   */
  async getVideoDuration(videoId, artworkId, accountId, apiKey) {
    // Check if duration already stored
    const artwork = await this.db
      .prepare('SELECT duration FROM artworks WHERE id = ?')
      .bind(artworkId)
      .first();
    
    if (artwork && artwork.duration && artwork.duration > 0) {
      return artwork.duration;
    }
    
    // Fetch from Cloudflare Stream
    const details = await this.getStreamVideoDetails(videoId, accountId, apiKey);
    
    if (details && details.duration) {
      const duration = Math.round(details.duration);
      
      // Cache in database
      await this.db
        .prepare('UPDATE artworks SET duration = ?, aspect_ratio = ? WHERE id = ?')
        .bind(duration, details.aspect_ratio, artworkId)
        .run();
      
      return duration;
    }
    
    return 0;
  }

  /**
   * Get localized cinematic data with optional duration fetch
   * @param {Artwork} artwork
   * @param {string} locale
   * @param {Object} [options]
   * @param {boolean} [options.fetchDuration] - Fetch duration from Stream API if not cached
   * @param {string} [options.accountId] - Cloudflare account ID
   * @param {string} [options.apiKey] - Cloudflare API key
   * @returns {Promise<Object>}
   */
  async getLocalizedCinematic(artwork, locale = 'es', options = {}) {
    let duration = artwork.duration || 0;
    
    // Optionally fetch real duration from Stream API
    if (options.fetchDuration && artwork.video_id && duration === 0) {
      if (options.accountId && options.apiKey) {
        duration = await this.getVideoDuration(
          artwork.video_id,
          artwork.id,
          options.accountId,
          options.apiKey
        );
      }
    }
    
    return {
      id: artwork.id,
      title: artwork.display_name || artwork.title,
      description: artwork.description,
      stream_video_id: artwork.video_id,
      thumbnail_url: artwork.image_id,
      duration: duration,
      view_count: artwork.view_count || 0,
      artwork: artwork,
      type: artwork.type,
      year: artwork.year,
      slug: artwork.slug,
      is_cinematic: artwork.is_cinematic,
      aspect_ratio: artwork.aspect_ratio
    };
  }

  /**
   * Record watch history for a user
   * @param {string} userId
   * @param {number} filmId
   * @param {number} progress - Progress in seconds
   * @returns {Promise<void>}
   */
  async recordWatchHistory(userId, filmId, progress) {
    try {
      const watched_at = Date.now();
      
      // Check if entry exists
      const existing = await this.db
        .prepare(
          `SELECT id FROM watch_history 
           WHERE user_id = ? AND film_id = ?
           ORDER BY watched_at DESC
           LIMIT 1`
        )
        .bind(userId, filmId)
        .first();
      
      if (existing) {
        // Update existing
        await this.db
          .prepare(
            `UPDATE watch_history 
             SET progress = ?, watched_at = ?
             WHERE id = ?`
          )
          .bind(progress, watched_at, existing.id)
          .run();
      } else {
        // Create new
        const { nanoid } = await import('nanoid');
        const id = nanoid();
        
        await this.db
          .prepare(
            `INSERT INTO watch_history (id, user_id, film_id, watched_at, progress)
             VALUES (?, ?, ?, ?, ?)`
          )
          .bind(id, userId, filmId, watched_at, progress)
          .run();
      }
    } catch (err) {
      console.error('Failed to record watch history:', err);
    }
  }

  /**
   * Get user's watch history
   * @param {string} userId
   * @param {number} limit
   * @returns {Promise<any[]>}
   */
  async getUserWatchHistory(userId, limit = 20) {
    try {
      const result = await this.db
        .prepare(
          `SELECT 
             a.*,
             w.watched_at,
             w.progress
           FROM watch_history w
           JOIN artworks a ON w.film_id = a.id
           WHERE w.user_id = ?
           AND a.video_id IS NOT NULL
           AND a.is_cinematic = 1
           ORDER BY w.watched_at DESC
           LIMIT ?`
        )
        .bind(userId, limit)
        .all();
      
      return result.results || [];
    } catch (err) {
      console.error('Failed to get watch history:', err);
      return [];
    }
  }

  /**
   * Clear user's watch history
   * @param {string} userId
   * @returns {Promise<void>}
   */
  async clearWatchHistory(userId) {
    try {
      await this.db
        .prepare('DELETE FROM watch_history WHERE user_id = ?')
        .bind(userId)
        .run();
    } catch (err) {
      console.error('Failed to clear watch history:', err);
      throw err;
    }
  }
}
