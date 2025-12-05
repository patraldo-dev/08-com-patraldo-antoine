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
   * Get featured artwork with video
   * @returns {Promise<Artwork | null>}
   */
  async getFeaturedFilm() {
    return await this.db
      .prepare(
        `SELECT * FROM artworks 
         WHERE video_id IS NOT NULL 
         AND published = 1 
         AND featured = 1 
         ORDER BY order_index DESC, created_at DESC 
         LIMIT 1`
      )
      .first();
  }

  /**
   * Get artwork by ID
   * @param {number} id
   * @returns {Promise<Artwork | null>}
   */
  async getFilmById(id) {
    return await this.db
      .prepare('SELECT * FROM artworks WHERE id = ? AND video_id IS NOT NULL')
      .bind(id)
      .first();
  }

  /**
   * Get all artworks with videos
   * @param {Object} options
   * @param {number} [options.limit]
   * @param {string} [options.type]
   * @returns {Promise<Artwork[]>}
   */
  async getAllFilms(options = {}) {
    const { limit = 100, type = null } = options;
    
    let query = 'SELECT * FROM artworks WHERE video_id IS NOT NULL AND published = 1';
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
   * Get related films (same type)
   * @param {string} type
   * @param {number} excludeId
   * @param {number} limit
   * @returns {Promise<Artwork[]>}
   */
  async getRelatedFilms(type, excludeId, limit = 6) {
    const result = await this.db
      .prepare(
        `SELECT * FROM artworks 
         WHERE video_id IS NOT NULL 
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
   * Get localized film data (artworks table doesn't have i18n, so just return as-is)
   * @param {Artwork} artwork
   * @param {string} locale
   * @returns {Object}
   */
  async getLocalizedFilm(artwork, locale = 'es') {
    // Since artworks table doesn't have multi-language fields,
    // we just format it to match the expected structure
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
      slug: artwork.slug
    };
  }
}
