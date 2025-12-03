// src/routes/canal/+page.server.js
import { CanalDatabase } from '$lib/server/canal-db.js';
import { error } from '@sveltejs/kit';

export async function load({ platform, locals }) {
  if (!platform?.env?.DB) {
    throw error(500, 'Database not configured');
  }

  // Pass both databases
  const db = new CanalDatabase(
    platform.env.DB,           // films table
    platform.env.ARTWORKS_DB   // artworks table (optional)
  );
  
  const featuredFilm = await db.getFeaturedFilm();
  
  if (!featuredFilm) {
    return {
      film: null,
      customerCode: platform.env.CLOUDFLARE_STREAM_CUSTOMER_CODE || ''
    };
  }
  
  const locale = locals.locale || 'es';
  const localizedFilm = await db.getLocalizedFilm(featuredFilm, locale);
  
  return {
    film: localizedFilm,
    customerCode: platform.env.CLOUDFLARE_STREAM_CUSTOMER_CODE || ''
  };
}
