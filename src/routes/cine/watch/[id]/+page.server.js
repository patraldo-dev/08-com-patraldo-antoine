// src/routes/cine/watch/[id]/+page.server.js
import { CineDatabase } from '#lib/server/cine-db.js';
import { error } from '@sveltejs/kit';
import { env } from 'cloudflare:workers';

export async function load({ platform, locals, params }) {
  if (!env?.ARTWORKS_DB) {
    throw error(500, 'Database not configured');
  }

  const db = new CineDatabase(
    env.ARTWORKS_DB,
    env.CLOUDFLARE_IMAGES_ACCOUNT_HASH
  );
  
  const artwork = await db.getCinematicById(parseInt(params.id)); // ← Changed
  
  if (!artwork) {
    return {
      film: null,
      customerCode: env.CLOUDFLARE_STREAM_CUSTOMER_CODE || '',
      relatedFilms: []
    };
  }
  
  const locale = locals.locale || 'es';
  const film = await db.getLocalizedCinematic(artwork, locale); // ← Changed
  
  const relatedArtworks = await db.getRelatedCinematics(artwork.type, artwork.id, 6); // ← Changed
  const relatedFilms = await Promise.all(
    relatedArtworks.map(a => db.getLocalizedCinematic(a, locale)) // ← Changed
  );
  
  return {
    film,
    customerCode: env.CLOUDFLARE_STREAM_CUSTOMER_CODE || '',
    cloudflareAccountHash: env.CLOUDFLARE_IMAGES_ACCOUNT_HASH || '',
    relatedFilms
  };
}
