import { CanalDatabase } from '$lib/server/canal-db.js';
import { error } from '@sveltejs/kit';

/**
 * @type {import('./$types').PageServerLoad}
 */
export async function load({ platform, locals, params }) {
  if (!platform?.env?.DB) {
    throw error(500, 'Database not configured');
  }

  const db = new CanalDatabase(platform.env.DB);
  const film = await db.getFilmById(params.id);
  
  if (!film) {
    throw error(404, 'Film not found');
  }
  
  const locale = locals.locale || 'es';
  const localizedFilm = db.getLocalizedFilm(film, locale);
  
  return {
    film: localizedFilm,
    customerCode: platform.env.CLOUDFLARE_STREAM_CUSTOMER_CODE || ''
  };
}
