// src/routes/tools/stickers/+page.server.js
/** @type {import('./$types').PageServerLoad} */
export async function load({ platform }) {
  // Query only published artworks with image_id
  const { results } = await platform.env.ARTWORKS_DB.prepare(`
    SELECT id, display_name, title, image_id
    FROM artworks
    WHERE published = 1 AND image_id IS NOT NULL
    ORDER BY order_index DESC, created_at DESC
  `).all();

  const artworks = results.map(art => ({
    id: String(art.id),            // use D1 id for selection uniqueness
    display_name: art.display_name,
    title: art.title,
    image_id: art.image_id         // ← Cloudflare Image ID
  }));

  return { artworks };
}
