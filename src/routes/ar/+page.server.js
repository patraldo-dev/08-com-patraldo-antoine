import { CF_IMAGES_ACCOUNT_HASH } from '$lib/config.js';

export async function load({ url, platform }) {
    const artworkId = url.searchParams.get('id');
    const mode = url.searchParams.get('mode') || 'wall';
    const db = platform?.env?.DB;

    let artworks = [];
    let selectedArtwork = null;

    if (db) {
        const result = await db.prepare(
            'SELECT id, display_name, title, year, image_id FROM artworks WHERE image_id IS NOT NULL ORDER BY created_at DESC'
        ).all();
        artworks = result.results.map(a => ({
            ...a,
            imageUrl: `https://imagedelivery.net/${CF_IMAGES_ACCOUNT_HASH}/${a.image_id}/public`
        }));

        if (artworkId) {
            selectedArtwork = artworks.find(a => a.id === artworkId || a.image_id === artworkId) || artworks[0];
        } else {
            selectedArtwork = artworks[0];
        }
    }

    return { artworks, selectedArtwork, mode };
}
