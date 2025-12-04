// src/routes/canal/gallery/+page.server.js
import { CanalDatabase } from '$lib/server/canal-db.js';
import { error } from '@sveltejs/kit';

export async function load({ platform, locals }) {
  if (!platform?.env?.ARTWORKS_DB) {
    throw error(500, 'Artworks database not configured');
  }

  const db = new CanalDatabase(platform.env.ARTWORKS_DB, {
    cloudflareAccountHash: platform.env.CLOUDFLARE_IMAGES_ACCOUNT_HASH
  });
  
  // Get all films with artwork data for grouping
  const allFilms = await db.getAllFilms({ limit: 100 });
  
  if (allFilms.length === 0) {
    return {
      films: [],
      groupedFilms: {},
      customerCode: platform.env.CLOUDFLARE_STREAM_CUSTOMER_CODE || '',
      error: 'No videos available'
    };
  }
  
  // Localize each film
  const locale = locals.locale || 'es';
  const localizedFilms = await Promise.all(
    allFilms.map(film => db.getLocalizedFilm(film, locale, {
      includeArtworkData: true // We need artwork.type for grouping
    }))
  );
  
  // Group by type
  const groupedFilms = {};
  localizedFilms.forEach(film => {
    const type = film.artwork?.type || 'Other';
    if (!groupedFilms[type]) {
      groupedFilms[type] = [];
    }
    groupedFilms[type].push(film);
  });

return {
  films: localizedFilms,
  groupedFilms,
  customerCode: platform.env.CLOUDFLARE_STREAM_CUSTOMER_CODE || '',
  cloudflareAccountHash: platform.env.CLOUDFLARE_IMAGES_ACCOUNT_HASH || ''
};
  
}
