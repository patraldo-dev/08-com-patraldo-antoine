import { CF_IMAGES_ACCOUNT_HASH } from '$lib/config.js';
import { error } from '@sveltejs/kit';

export async function load({ params, platform }) {
  const { storySlug, chapterSlug } = params;
  
  const dbArtworks = platform?.env?.ARTWORKS_DB;
  const dbStories = platform?.env?.stories_db;

  if (!dbStories || !dbArtworks) {
    throw error(503, 'Database connection unavailable');
  }

  try {
    // 1. Get the Chapter info from stories_db
    const chapterResult = await dbStories.prepare(`
      SELECT 
        sc.id as chapter_id,
        sc.story_id,
        sc.artwork_id,  -- Now this column exists
        sc.title as chapter_title,
        sc.slug,
        s.title as story_title,
        s.slug as story_slug
      FROM story_chapters sc
      JOIN stories s ON sc.story_id = s.id
      WHERE sc.slug = ? AND s.slug = ?
    `).bind(chapterSlug, storySlug).first();

    if (!chapterResult) {
      throw error(404, 'Chapter not found');
    }

    // If there is no artwork linked, we can't show the image/video
    if (!chapterResult.artwork_id) {
        console.warn(`Chapter ${chapterResult.chapter_id} has no artwork linked.`);
        // You could redirect or return minimal data here
        // For now, we'll return the chapter info but no artwork
    }

    // 2. Get the Story Content from ARTWORKS_DB (if artwork exists)
    let contentResult = [];
    if (chapterResult.artwork_id) {
        const res = await dbArtworks.prepare(`
            SELECT content_type, content_text, media_id, video_id, order_index
            FROM story_content
            WHERE artwork_id = ? 
            ORDER BY order_index ASC
        `).bind(chapterResult.artwork_id).all();
        contentResult = res.results;
    }

    // 3. Get the Artwork Details from ARTWORKS_DB
    let artworkResult = null;
    if (chapterResult.artwork_id) {
        artworkResult = await dbArtworks.prepare(`
            SELECT 
            id, title, display_name, description, year, 
            image_id, video_id, type, aspect_ratio,
            transform_rotation_x, transform_rotation_y, transform_rotation_z,
            transform_position_x, transform_position_y, transform_position_z,
            transform_scale_x, transform_scale_y, transform_scale_z
            FROM artworks
            WHERE id = ?
        `).bind(chapterResult.artwork_id).first();
    }

    const thumbnailUrl = artworkResult?.image_id 
      ? `https://imagedelivery.net/${CF_IMAGES_ACCOUNT_HASH}/${artworkResult.image_id}/thumbnail`
      : null;

    return {
      chapter: {
        id: chapterResult.chapter_id,
        title: chapterResult.chapter_title,
        slug: chapterResult.slug,
        storyTitle: chapterResult.story_title,
        storySlug: chapterResult.story_slug
      },
      content: contentResult || [],
      artwork: artworkResult ? {
        ...artworkResult,
        thumbnailUrl: thumbnailUrl
      } : null
    };

  } catch (e) {
    if (e.status) throw e; 
    console.error('Error loading chapter:', e);
    throw error(500, 'Failed to load story chapter');
  }
}
