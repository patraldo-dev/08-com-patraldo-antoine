import { CF_IMAGES_ACCOUNT_HASH } from '$lib/config.js';

export async function load({ platform }) {
  const dbStories = platform?.env?.stories_db;
  const dbArtworks = platform?.env?.ARTWORKS_DB;

  if (!dbStories || !dbArtworks) {
    return { stories: [] };
  }

  try {
    // We query the STORIES table, but join it with chapters and artworks
    // to get the cover image (artwork.image_id) for the card display.
    // We assume the first chapter (order_index=1) has the cover art.
    const result = await dbStories.prepare(`
      SELECT 
        s.id as story_id,
        s.title as story_title,
        s.slug as story_slug,
        s.description as story_description,
        a.id as artwork_id,
        a.display_name,
        a.image_id,
        a.year
      FROM stories s
      LEFT JOIN story_chapters sc ON s.id = sc.story_id AND sc.order_index = 1
      LEFT JOIN artworks a ON sc.artwork_id = a.id
      ORDER BY s.created_at DESC
    `).all();

    const stories = result.results.map(row => ({
      id: row.story_id,
      title: row.story_title, // Use Story Title
      slug: row.story_slug,
      description: row.story_description,
      year: row.year,
      // Fallbacks if no artwork is linked yet
      display_name: row.display_name || row.story_title,
      thumbnailId: row.image_id || null,
      story_intro: row.story_description // Use description as intro for the card
    }));

    return { stories };

  } catch (e) {
    console.error("Error loading stories index:", e);
    return { stories: [] };
  }
}
