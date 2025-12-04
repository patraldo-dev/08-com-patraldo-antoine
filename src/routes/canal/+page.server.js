// src/routes/canal/+page.server.js
import { CanalDatabase } from '$lib/server/canal-db.js';

export async function load({ platform, locals }) {
  if (!platform?.env?.ARTWORKS_DB) {
    return {
      film: null,
      customerCode: platform.env.CLOUDFLARE_STREAM_CUSTOMER_CODE || ''
    };
  }

  const db = new CanalDatabase(
    platform.env.ARTWORKS_DB,
    platform.env.CLOUDFLARE_IMAGES_ACCOUNT_HASH
  );
  
  const featuredArtwork = await db.getFeaturedFilm();
  
  if (!featuredArtwork) {
    return {
      film: null,
      customerCode: platform.env.CLOUDFLARE_STREAM_CUSTOMER_CODE || ''
    };
  }
  
  const locale = locals.locale || 'es';
  const film = await db.getLocalizedFilm(featuredArtwork, locale);
  
  return {
    film,
    customerCode: platform.env.CLOUDFLARE_STREAM_CUSTOMER_CODE || ''
  };
}
