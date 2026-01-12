import { json } from '@sveltejs/kit';
import { 
  saveArtworkTransform, 
  getArtworkWithTransform,
  resetArtworkTransform
} from '$lib/db/artwork-transforms.js';

/**
 * GET - Retrieve artwork with transformation data
 * @param {import('@sveltejs/kit').RequestEvent} event
 */
export async function GET({ params, platform }) {
  const { id } = params;
  
  if (!platform?.env?.DB) {
    return json({ error: 'Database not available' }, { status: 500 });
  }

  try {
    const artworkId = parseInt(id);
    
    if (isNaN(artworkId)) {
      return json({ error: 'Invalid artwork ID' }, { status: 400 });
    }

    const artwork = await getArtworkWithTransform(platform.env.DB, artworkId);
    
    if (!artwork) {
      return json({ error: 'Artwork not found' }, { status: 404 });
    }

    return json(artwork);
  } catch (error) {
    console.error('Get artwork transform error:', error);
    return json({ error: error.message }, { status: 500 });
  }
}

/**
 * POST - Save transformation for artwork
 * @param {import('@sveltejs/kit').RequestEvent} event
 */
export async function POST({ params, request, platform }) {
  const { id } = params;
  
  if (!platform?.env?.DB) {
    return json({ error: 'Database not available' }, { status: 500 });
  }

  try {
    const artworkId = parseInt(id);
    
    if (isNaN(artworkId)) {
      return json({ error: 'Invalid artwork ID' }, { status: 400 });
    }

    const body = await request.json();
    const { transform, reset = false } = body;

    if (reset) {
      await resetArtworkTransform(platform.env.DB, artworkId);
    } else if (transform) {
      // Validate transform structure
      if (!transform.rotation || !transform.position || !transform.scale) {
        return json({ error: 'Invalid transform structure' }, { status: 400 });
      }

      await saveArtworkTransform(platform.env.DB, artworkId, transform);
    } else {
      return json({ error: 'Transform data or reset flag required' }, { status: 400 });
    }

    return json({ success: true });
  } catch (error) {
    console.error('Save transform error:', error);
    return json({ error: error.message }, { status: 500 });
  }
}

/**
 * DELETE - Reset transformation for artwork
 * @param {import('@sveltejs/kit').RequestEvent} event
 */
export async function DELETE({ params, platform }) {
  const { id } = params;
  
  if (!platform?.env?.DB) {
    return json({ error: 'Database not available' }, { status: 500 });
  }

  try {
    const artworkId = parseInt(id);
    
    if (isNaN(artworkId)) {
      return json({ error: 'Invalid artwork ID' }, { status: 400 });
    }

    await resetArtworkTransform(platform.env.DB, artworkId);

    return json({ success: true });
  } catch (error) {
    console.error('Reset transform error:', error);
    return json({ error: error.message }, { status: 500 });
  }
}
