// src/routes/canal/gallery/+page.server.js
import { CanalDatabase } from '$lib/server/canal-db.js';
import { error } from '@sveltejs/kit';

export async function load({ platform, locals }) {
  if (!platform?.env?.ARTWORKS_DB) {
    throw error(500, 'Database not configured');
  }

  const db = new CanalDatabase(
    platform.env.ARTWORKS_DB,
    platform.env.CLOUDFLARE_IMAGES_ACCOUNT_HASH
  );
  
  try {
    const artworks = await db.getAllFilms({ limit: 100 });
    
    if (artworks.length === 0) {
      return {
        films: [],
        groupedFilms: {},
        customerCode: platform.env.CLOUDFLARE_STREAM_CUSTOMER_CODE || '',
        cloudflareAccountHash: platform.env.CLOUDFLARE_IMAGES_ACCOUNT_HASH || ''
      };
    }
    
    const locale = locals.locale || 'es';
    const films = await Promise.all(
      artworks.map(artwork => db.getLocalizedFilm(artwork, locale))
    );
    
    // Group by type
    const groupedFilms = {};
    films.forEach(film => {
      const type = film.type || 'Other';
      if (!groupedFilms[type]) {
        groupedFilms[type] = [];
      }
      groupedFilms[type].push(film);
    });
    
    return {
      films,
      groupedFilms,
      customerCode: platform.env.CLOUDFLARE_STREAM_CUSTOMER_CODE || '',
      cloudflareAccountHash: platform.env.CLOUDFLARE_IMAGES_ACCOUNT_HASH || ''
    };
  } catch (err) {
    console.error('Gallery load error:', err);
    throw error(500, 'Failed to load gallery');
  }
}
