// src/routes/canal/watch/[id]/+page.server.js
import { CanalDatabase } from '$lib/server/canal-db.js';
import { error } from '@sveltejs/kit';

export async function load({ platform, locals, params }) {
  if (!platform?.env?.ARTWORKS_DB) {
    throw error(500, 'Database not configured');
  }

  const db = new CanalDatabase(
    platform.env.ARTWORKS_DB,
    platform.env.CLOUDFLARE_IMAGES_ACCOUNT_HASH
  );
  
  // Get the artwork/film
  const artwork = await db.getFilmById(parseInt(params.id));
  
  if (!artwork) {
    return {
      film: null,
      customerCode: platform.env.CLOUDFLARE_STREAM_CUSTOMER_CODE || '',
      relatedFilms: []
    };
  }
  
  const locale = locals.locale || 'es';
  const film = await db.getLocalizedFilm(artwork, locale);
  
  // Get related videos (same type)
  const relatedArtworks = await db.getRelatedFilms(artwork.type, artwork.id, 6);
  const relatedFilms = await Promise.all(
    relatedArtworks.map(a => db.getLocalizedFilm(a, locale))
  );
  
  return {
    film,
    customerCode: platform.env.CLOUDFLARE_STREAM_CUSTOMER_CODE || '',
    cloudflareAccountHash: platform.env.CLOUDFLARE_IMAGES_ACCOUNT_HASH || '',
    relatedFilms
  };
}
