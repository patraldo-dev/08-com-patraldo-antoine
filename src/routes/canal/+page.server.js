// src/routes/canal/+page.server.js
import { CanalDatabase } from '$lib/server/canal-db.js';
import { error } from '@sveltejs/kit';

export async function load({ platform, locals }) {
  if (!platform?.env?.DB) {
    throw error(500, 'Database not configured');
  }

  const db = new CanalDatabase(platform.env.DB);
  const featuredFilm = await db.getFeaturedFilm();
  
  if (!featuredFilm) {
    // Instead of throwing, return a flag for the client to handle with i18n
    return {
      film: null,
      customerCode: platform.env.CLOUDFLARE_STREAM_CUSTOMER_CODE || ''
    };
  }
  
  const locale = locals.locale || 'es';
  const localizedFilm = db.getLocalizedFilm(featuredFilm, locale);
  
  return {
    film: localizedFilm,
    customerCode: platform.env.CLOUDFLARE_STREAM_CUSTOMER_CODE || ''
  };
}
