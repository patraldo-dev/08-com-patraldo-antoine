// src/lib/server/canal-db.js
import { nanoid } from 'nanoid';

/**
 * @typedef {Object} Film
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
 * @property {number} [artwork_id] - Optional link to artwork in ARTWORKS_DB
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
 * @property {number} [artwork_id]
 * @property {Object} [artwork] - Optional linked artwork data
 */

export class CanalDatabase {
  /**
   * @param {import('@cloudflare/workers-types').D1Database} db - artist-portfolio-db
   * @param {import('@cloudflare/workers-types').D1Database} [artworksDb] - antoine-artworks (optional)
   */
  constructor(db, artworksDb = null) {
    this.db = db;
    this.artworksDb = artworksDb;
  }

  /**
   * Get localized film data with optional artwork
   * @param {Film} film
   * @param {string} locale - es, en, fr (or es-MX, en-US, fr-CA)
   * @returns {Promise<LocalizedFilm>}
   */
  async getLocalizedFilm(film, locale = 'es') {
    const lang = locale.split('-')[0];
    
    const localizedFilm = {
      id: film.id,
      title: film[`title_${lang}`] || film.title_es,
      description: film[`description_${lang}`] || film.description_es,
      stream_video_id: film.stream_video_id,
      thumbnail_url: film.thumbnail_url,
      duration: film.duration,
      is_featured: film.is_featured,
      created_at: film.created_at,
      view_count: film.view_count,
      artwork_id: film.artwork_id
    };

    // If film is linked to artwork and we have artworks DB, fetch artwork
    if (film.artwork_id && this.artworksDb) {
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
   * @returns {Promise<Film | null>}
   */
  async getFeaturedFilm() {
    return await this.db
      .prepare('SELECT * FROM films WHERE is_featured = 1 ORDER BY created_at DESC LIMIT 1')
      .first();
  }

  /**
   * @param {string} id
   * @returns {Promise<Film | null>}
   */
  async getFilmById(id) {
    return await this.db
      .prepare('SELECT * FROM films WHERE id = ?')
      .bind(id)
      .first();
  }

  /**
   * @returns {Promise<Film[]>}
   */
  async getAllFilms() {
    const result = await this.db
      .prepare('SELECT * FROM films ORDER BY created_at DESC')
      .all();
    return result.results;
  }

  /**
   * @param {string} filmId
   * @returns {Promise<void>}
   */
  async incrementViewCount(filmId) {
    await this.db
      .prepare('UPDATE films SET view_count = view_count + 1 WHERE id = ?')
      .bind(filmId)
      .run();
  }

  /**
   * @param {string} userId
   * @param {string} filmId
   * @param {number} progress
   * @returns {Promise<void>}
   */
  async recordWatchHistory(userId, filmId, progress) {
    const id = nanoid();
    const watched_at = Date.now();

    await this.db
      .prepare(
        'INSERT INTO watch_history (id, user_id, film_id, watched_at, progress) VALUES (?, ?, ?, ?, ?)'
      )
      .bind(id, userId, filmId, watched_at, progress)
      .run();
  }

  /**
   * @param {string} userId
   * @param {number} limit
   * @returns {Promise<any[]>}
   */
  async getUserWatchHistory(userId, limit = 20) {
    const result = await this.db
      .prepare(
        `SELECT f.*, w.watched_at, w.progress
         FROM watch_history w
         JOIN films f ON w.film_id = f.id
         WHERE w.user_id = ?
         ORDER BY w.watched_at DESC
         LIMIT ?`
      )
      .bind(userId, limit)
      .all();
    return result.results;
  }
}
