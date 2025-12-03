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
 */

export class ChannelDatabase {
  /**
   * @param {import('@cloudflare/workers-types').D1Database} db
   */
  constructor(db) {
    this.db = db;
  }

  /**
   * Get localized film data based on locale
   * @param {Film} film
   * @param {string} locale - Locale code (es, en, fr)
   * @returns {Object} Localized film object
   */
  getLocalizedFilm(film, locale = 'es') {
    // Map full locale codes to language codes
    const lang = locale.split('-')[0];
    
    return {
      ...film,
      title: film[`title_${lang}`] || film.title_es,
      description: film[`description_${lang}`] || film.description_es
    };
  }

  /**
   * Get the featured film
   * @returns {Promise<Film | null>}
   */
  async getFeaturedFilm() {
    const result = await this.db
      .prepare('SELECT * FROM films WHERE is_featured = 1 ORDER BY created_at DESC LIMIT 1')
      .first();
    return result;
  }

  /**
   * Get film by ID
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
   * Get all films
   * @returns {Promise<Film[]>}
   */
  async getAllFilms() {
    const result = await this.db
      .prepare('SELECT * FROM films ORDER BY created_at DESC')
      .all();
    return result.results;
  }

  /**
   * Create a new film
   * @param {Omit<Film, 'id' | 'created_at' | 'view_count'>} film
   * @returns {Promise<Film>}
   */
  async createFilm(film) {
    const id = nanoid();
    const created_at = Date.now();
    
    await this.db
      .prepare(
        `INSERT INTO films (id, title_es, title_en, title_fr, description_es, description_en, description_fr, 
         stream_video_id, thumbnail_url, duration, is_featured, created_at, view_count)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 0)`
      )
      .bind(
        id,
        film.title_es,
        film.title_en,
        film.title_fr,
        film.description_es,
        film.description_en,
        film.description_fr,
        film.stream_video_id,
        film.thumbnail_url,
        film.duration,
        film.is_featured,
        created_at
      )
      .run();

    return { ...film, id, created_at, view_count: 0 };
  }

  /**
   * Increment view count for a film
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
   * Record watch history for a user
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
        `INSERT INTO watch_history (id, user_id, film_id, watched_at, progress)
         VALUES (?, ?, ?, ?, ?)`
      )
      .bind(id, userId, filmId, watched_at, progress)
      .run();
  }

  /**
   * Get user's watch history
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
