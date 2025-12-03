// src/routes/canal/+page.server.js
import { CanalDatabase } from '$lib/server/canal-db.js';
import { error } from '@sveltejs/kit';

export async function load({ platform, locals }) {
  if (!platform?.env?.ARTWORKS_DB) {
    throw error(500, 'Artworks database not configured');
  }

  const db = new CanalDatabase(platform.env.ARTWORKS_DB, {
    cloudflareAccountHash: platform.env.CLOUDFLARE_IMAGES_ACCOUNT_HASH,
    defaultCustomerCode: platform.env.CLOUDFLARE_STREAM_CUSTOMER_CODE
  });
  
  const featuredFilm = await db.getFeaturedFilm();
  
  if (!featuredFilm) {
    return {
      film: null,
      customerCode: platform.env.CLOUDFLARE_STREAM_CUSTOMER_CODE || '',
      error: 'No video content available'
    };
  }
  
  const locale = locals.locale || 'es';
  const localizedFilm = await db.getLocalizedFilm(featuredFilm, locale);
  
  return {
    film: localizedFilm,
    customerCode: platform.env.CLOUDFLARE_STREAM_CUSTOMER_CODE || ''
  };
}
