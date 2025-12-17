import { json, error } from '@sveltejs/kit';
import { CineDatabase } from '$lib/server/cine-db.js';

/**
 * @type {import('./$types').RequestHandler}
 */
export async function GET({ platform, locals, url }) {
  if (!platform?.env?.DB) {
    throw error(500, 'Database not configured');
  }

  try {
    const db = new CineDatabase(platform.env.DB);
    const locale = locals.locale || url.searchParams.get('locale') || 'es';
    const films = await db.getAllFilms();
    
    const localizedFilms = films.map(film => db.getLocalizedFilm(film, locale));
    
    return json({ films: localizedFilms });
  } catch (err) {
    console.error('Failed to fetch films:', err);
    throw error(500, 'Failed to fetch films');
  }
}
