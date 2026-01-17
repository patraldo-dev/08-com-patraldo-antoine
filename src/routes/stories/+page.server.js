// src/routes/stories/+page.server.js
import { CF_IMAGES_ACCOUNT_HASH } from '$lib/config.js';

export async function load({ platform }) {
  const dbStories = platform?.env?.stories_db;
  const dbArtworks = platform?.env?.ARTWORKS_DB;

  if (!dbStories || !dbArtworks) {
    return { stories: [] };
  }

  try {
    let allStories = [];

    // 1. FETCH FULL STORIES (From Admin Panel / stories_db)
    // These have a slug and link to a full page
    const newStoriesResult = await dbStories.prepare(`
      SELECT 
        s.id as id,
        s.title as title,
        s.slug as slug,
        s.description as description,
        a.image_id,
        a.year,
        s.created_at as created_at
      FROM stories s
      LEFT JOIN story_chapters sc ON s.id = sc.story_id AND sc.order_index = 1
      LEFT JOIN artworks a ON sc.artwork_id = a.id
      ORDER BY s.created_at DESC
    `).all();

    // Transform new stories
    const newStories = newStoriesResult.results.map(row => ({
      ...row,
      type: 'full', // Flag to distinguish later
      thumbnailUrl: row.image_id 
        ? `https://imagedelivery.net/${CF_IMAGES_ACCOUNT_HASH}/${row.image_id}/gallery`
        : '/placeholder.png'
    }));

    allStories = [...allStories, ...newStories];

    // 2. FETCH INTRO STORIES (From Bash Script / artworks table)
    // These have no slug, so they link to the Modal
    const introStoriesResult = await dbArtworks.prepare(`
      SELECT 
        id, 
        title, 
        display_name, 
        image_id, 
        story_intro, 
        year, 
        created_at
      FROM artworks
      WHERE story_enabled = 1
      ORDER BY created_at DESC
    `).all();

    // Transform intro stories
    const introStories = introStoriesResult.results.map(row => ({
      ...row,
      title: row.display_name || row.title, // Use display name for card
      slug: null, // NULL means no full page exists
      description: row.story_intro || row.description,
      type: 'intro', // Flag to distinguish later
      thumbnailUrl: row.image_id
        ? `https://imagedelivery.net/${CF_IMAGES_ACCOUNT_HASH}/${row.image_id}/gallery`
        : '/placeholder.png'
    }));

    allStories = [...allStories, ...introStories];

    // 3. SORT ALL TOGETHER
    // Sort by creation date so newest appears first
    allStories.sort((a, b) => new Date(b.created_at) - new Date(a.created_at));

    return { stories: allStories };

  } catch (e) {
    console.error("Error loading combined stories:", e);
    return { stories: [] };
  }
}
