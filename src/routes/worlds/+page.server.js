// src/routes/worlds/+page.server.js
import { CF_IMAGES_ACCOUNT_HASH } from '$lib/config.js';

// Load published artworks so the engine can bind live collection pieces to
// portal doorways (falling back to explicit `art` bindings in each world config).
export async function load({ platform, url }) {
	const artworks = [];
	// `platform.env` holds Cloudflare bindings (D1, etc.) at runtime; cast to
	// any because wrangler bindings aren't reflected in the TS platform types.
	/** @type {any} */
	const pf = platform;
	/** @type {any} */
	const env = pf?.env ?? {};

	try {
		const db = env.ARTWORKS_DB;
		if (db) {
			const result = await db
				.prepare(`
					SELECT id, title, display_name, image_id, year
					FROM artworks
					WHERE published = 1 AND image_id IS NOT NULL
					ORDER BY order_index DESC, year DESC
				`)
				.all();

			for (const a of result.results || []) {
				if (!a.image_id) continue;
				artworks.push({
					id: a.id,
					title: a.display_name || a.title,
					image_id: a.image_id,
					year: a.year
				});
			}
		}
	} catch (error) {
		console.error('[worlds] Error loading artworks:', error);
	}

	// Allow a deep link /worlds?world=<id> to pick the start world.
	const startWorld = url.searchParams.get('world') || null;

	return {
		artworks,
		cfHash: CF_IMAGES_ACCOUNT_HASH,
		startWorld
	};
}
