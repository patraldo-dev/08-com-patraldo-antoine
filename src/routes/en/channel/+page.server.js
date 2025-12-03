import { ChannelDatabase } from '$lib/server/channel-db.js';
import { error } from '@sveltejs/kit';

/**
 * @type {import('./$types').PageServerLoad}
 */
export async function load({ platform, locals }) {
  if (!platform?.env?.DB) {
    throw error(500, 'Database not configured');
  }

  const db = new ChannelDatabase(platform.env.DB);
  const featuredFilm = await db.getFeaturedFilm();
  
  if (!featuredFilm) {
    throw error(404, 'No featured film available');
  }
  
  const locale = locals.locale || 'es';
  const localizedFilm = db.getLocalizedFilm(featuredFilm, locale);
  
  return {
    film: localizedFilm,
    customerCode: platform.env.CLOUDFLARE_STREAM_CUSTOMER_CODE || 'CUSTOMER_CODE_NOT_SET',
    locale: locale
  };
}
