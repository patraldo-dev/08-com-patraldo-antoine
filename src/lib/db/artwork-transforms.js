/**
 * Database operations for artwork 3D transformations
 */

/**
 * Get all artworks with transformations
 */
export async function getAllArtworksWithTransforms(db, options = {}) {
  const published = options.published !== false ? 1 : 0;
  
  let query = `
    SELECT id, title, slug, type, image_id, video_id, description,
           transform_rotation_x, transform_rotation_y, transform_rotation_z,
           transform_position_x, transform_position_y, transform_position_z,
           transform_scale_x, transform_scale_y, transform_scale_z,
           is_cinematic, aspect_ratio, featured, order_index, year
    FROM artworks 
    WHERE published = ?
    ORDER BY order_index ASC, id DESC
  `;
  
  const { results } = await db.prepare(query).bind(published).all();

  return results.map(artwork => ({
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
 * Get artwork with transformation data
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
 * Save 3D transformation for an artwork
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
 * Reset transformation for an artwork
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
