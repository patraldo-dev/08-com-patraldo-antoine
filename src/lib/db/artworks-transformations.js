/**
 * Database operations for artwork 3D transformations
 * Works with the existing artworks table and its transform_* columns
 */

/**
 * Save 3D transformation for an artwork
 * @param {D1Database} db - Cloudflare D1 database instance
 * @param {number} artworkId - The artwork ID
 * @param {Object} transform - The transformation object
 * @param {{x: number, y: number, z: number}} transform.rotation - Rotation values
 * @param {{x: number, y: number, z: number}} transform.position - Position values
 * @param {{x: number, y: number, z: number}} transform.scale - Scale values
 * @returns {Promise<void>}
 */
export async function saveArtworkTransform(db, artworkId, transform) {
  const now = new Date().toISOString();
  
  await db.prepare(`
    UPDATE artworks SET
      transform_rotation_x = ?,
      transform_rotation_y = ?,
      transform_rotation_z = ?,
      transform_position_x = ?,
      transform_position_y = ?,
      transform_position_z = ?,
      transform_scale_x = ?,
      transform_scale_y = ?,
      transform_scale_z = ?,
      updated_at = ?
    WHERE id = ?
  `).bind(
    transform.rotation.x,
    transform.rotation.y,
    transform.rotation.z,
    transform.position.x,
    transform.position.y,
    transform.position.z,
    transform.scale.x,
    transform.scale.y,
    transform.scale.z,
    now,
    artworkId
  ).run();
}

/**
 * Get artwork with transformation data
 * @param {D1Database} db - Cloudflare D1 database instance
 * @param {number} artworkId - The artwork ID
 * @returns {Promise<Object|null>} The artwork with transform or null
 */
export async function getArtworkWithTransform(db, artworkId) {
  const result = await db.prepare(`
    SELECT id, title, slug, type, image_id, video_id, description,
           transform_rotation_x, transform_rotation_y, transform_rotation_z,
           transform_position_x, transform_position_y, transform_position_z,
           transform_scale_x, transform_scale_y, transform_scale_z,
           is_cinematic, aspect_ratio, featured, year
    FROM artworks 
    WHERE id = ?
  `).bind(artworkId).first();

  if (!result) return null;

  return {
    id: result.id,
    title: result.title,
    slug: result.slug,
    type: result.type,
    imageId: result.image_id,
    videoId: result.video_id,
    description: result.description,
    isCinematic: result.is_cinematic,
    aspectRatio: result.aspect_ratio,
    featured: result.featured,
    year: result.year,
    transform: {
      rotation: {
        x: result.transform_rotation_x || 0,
        y: result.transform_rotation_y || 0,
        z: result.transform_rotation_z || 0
      },
      position: {
        x: result.transform_position_x || 0,
        y: result.transform_position_y || 0,
        z: result.transform_position_z || 0
      },
      scale: {
        x: result.transform_scale_x || 1,
        y: result.transform_scale_y || 1,
        z: result.transform_scale_z || 1
      }
    }
  };
}

/**
 * Get all artworks with transformations
 * @param {D1Database} db - Cloudflare D1 database instance
 * @param {Object} options - Query options
 * @param {boolean} options.published - Filter by published status
 * @param {boolean|null} options.featured - Filter by featured status
 * @param {string|null} options.type - Filter by artwork type
 * @returns {Promise<Array>} Array of artworks with transforms
 */
export async function getAllArtworksWithTransforms(db, options = {}) {
  const { published = true, featured = null, type = null } = options;
  
  let query = `
    SELECT id, title, slug, type, image_id, video_id, description,
           transform_rotation_x, transform_rotation_y, transform_rotation_z,
           transform_position_x, transform_position_y, transform_position_z,
           transform_scale_x, transform_scale_y, transform_scale_z,
           is_cinematic, aspect_ratio, featured, order_index, year
    FROM artworks 
    WHERE published = ?
  `;
  
  const bindings = [published ? 1 : 0];
  
  if (featured !== null) {
    query += ` AND featured = ?`;
    bindings.push(featured ? 1 : 0);
  }
  
  if (type !== null) {
    query += ` AND type = ?`;
    bindings.push(type);
  }
  
  query += ` ORDER BY order_index ASC, id DESC`;
  
  const results = await db.prepare(query).bind(...bindings).all();

  return results.results.map(artwork => ({
    id: artwork.id,
    title: artwork.title,
    slug: artwork.slug,
    type: artwork.type,
    imageId: artwork.image_id,
    videoId: artwork.video_id,
    description: artwork.description,
    isCinematic: artwork.is_cinematic,
    aspectRatio: artwork.aspect_ratio,
    featured: artwork.featured,
    orderIndex: artwork.order_index,
    year: artwork.year,
    transform: {
      rotation: {
        x: artwork.transform_rotation_x || 0,
        y: artwork.transform_rotation_y || 0,
        z: artwork.transform_rotation_z || 0
      },
      position: {
        x: artwork.transform_position_x || 0,
        y: artwork.transform_position_y || 0,
        z: artwork.transform_position_z || 0
      },
      scale: {
        x: artwork.transform_scale_x || 1,
        y: artwork.transform_scale_y || 1,
        z: artwork.transform_scale_z || 1
      }
    }
  }));
}

/**
 * Reset transformation for an artwork
 * @param {D1Database} db - Cloudflare D1 database instance
 * @param {number} artworkId - The artwork ID
 * @returns {Promise<void>}
 */
export async function resetArtworkTransform(db, artworkId) {
  const now = new Date().toISOString();
  
  await db.prepare(`
    UPDATE artworks SET
      transform_rotation_x = 0,
      transform_rotation_y = 0,
      transform_rotation_z = 0,
      transform_position_x = 0,
      transform_position_y = 0,
      transform_position_z = 0,
      transform_scale_x = 1,
      transform_scale_y = 1,
      transform_scale_z = 1,
      updated_at = ?
    WHERE id = ?
  `).bind(now, artworkId).run();
}
