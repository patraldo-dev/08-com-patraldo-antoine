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
    // Get today's "seed" for consistent daily rotation
    const today = new Date().toISOString().split('T')[0]; // YYYY-MM-DD
    const seed = today.split('-').join(''); // YYYYMMDD as number
    
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
   * Get localized cinematic data
   * @param {Artwork} artwork
   * @param {string} locale
   * @returns {Promise<Object>}
   */
  async getLocalizedCinematic(artwork, locale = 'es') {
    return {
      id: artwork.id,
      title: artwork.display_name || artwork.title,
      description: artwork.description,
      stream_video_id: artwork.video_id,
      thumbnail_url: artwork.image_id,
      duration: 0, // Artworks table doesn't store duration
      view_count: 0, // Artworks table doesn't track views
      artwork: artwork, // Include full artwork data
      type: artwork.type,
      year: artwork.year,
      slug: artwork.slug,
      is_cinematic: artwork.is_cinematic,
      aspect_ratio: artwork.aspect_ratio
    };
  }
}
