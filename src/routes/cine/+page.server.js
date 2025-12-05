// src/routes/cine/+page.server.js
import { CineDatabase } from '$lib/server/cine-db.js';

export async function load({ platform, locals }) {
  if (!platform?.env?.ARTWORKS_DB) {
    return {
      film: null,
      customerCode: platform.env.CLOUDFLARE_STREAM_CUSTOMER_CODE || ''
    };
  }

  const db = new CineDatabase(
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
