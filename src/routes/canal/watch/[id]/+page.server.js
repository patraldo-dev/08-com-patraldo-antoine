// src/routes/canal/watch/[id]/+page.server.js
import { CanalDatabase } from '$lib/server/canal-db.js';
import { error } from '@sveltejs/kit';

export async function load({ params, platform, locals }) {
  if (!platform?.env?.ARTWORKS_DB) {
    throw error(500, 'Artworks database not configured');
  }

  const db = new CanalDatabase(platform.env.ARTWORKS_DB, {
    cloudflareAccountHash: platform.env.CLOUDFLARE_IMAGES_ACCOUNT_HASH
  });
  
  // Extract artwork ID from film ID (artwork-123 → 123)
  const artworkId = params.id.replace('artwork-', '');
  
  const film = await db.getFilmByArtworkId(parseInt(artworkId), {
    includeArtworkData: true
  });
  
  if (!film) {
    throw error(404, 'Video not found');
  }
  
  // Increment view count (async, don't await)
  db.incrementViewCount(film.id);
  
  const locale = locals.locale || 'es';
  const localizedFilm = await db.getLocalizedFilm(film, locale, {
    includeArtworkData: true
  });
  
  // Get related films (excluding current one)
  const allFilms = await db.getAllFilms({ limit: 5 });
  const relatedFilms = allFilms
    .filter(f => f.id !== film.id)
    .slice(0, 4);
  
  // Localize related films
  const localizedRelatedFilms = await Promise.all(
    relatedFilms.map(relatedFilm => 
      db.getLocalizedFilm(relatedFilm, locale, { includeArtworkData: true })
    )
  );
  
  return {
    film: localizedFilm,
    customerCode: platform.env.CLOUDFLARE_STREAM_CUSTOMER_CODE || '',
    relatedFilms: localizedRelatedFilms
  };
}
