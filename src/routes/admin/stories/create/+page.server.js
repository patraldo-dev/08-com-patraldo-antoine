// src/routes/admin/stories/create/+page.server.js
import { error, redirect } from '@sveltejs/kit';

export const actions = {
  default: async ({ request, platform }) => {
    const formData = await request.formData();
    const storyTitle = formData.get('title');
    const storySlug = formData.get('slug');
    const chapterTitle = formData.get('chapterTitle');
    const content = formData.get('content');
    const artworkId = formData.get('artworkId'); 

    // Get BOTH bindings
    const dbStories = platform?.env?.stories_db;
    const dbArtworks = platform?.env?.ARTWORKS_DB;

    if (!dbStories || !dbArtworks) {
      return { error: 'Database connection unavailable (Missing Bindings)' };
    }

    try {
      // 1. Create the Story (in stories_db)
      const storyResult = await dbStories.prepare(`
        INSERT INTO stories (title, slug, created_at, updated_at)
        VALUES (?, ?, datetime('now'), datetime('now'))
      `).bind(storyTitle, storySlug).run();

      const storyId = storyResult.meta.last_row_id;

      // 2. Create the Chapter (in stories_db)
      const chapterResult = await dbStories.prepare(`
        INSERT INTO story_chapters (story_id, title, slug, order_index, created_at, updated_at)
        VALUES (?, ?, 'chapter-1', 1, datetime('now'), datetime('now'))
      `).bind(storyId, chapterTitle || 'Chapter 1').run();

      // 3. Insert the Content (in ARTWORKS_DB)
      // The story_content table lives in antoine-artworks DB
      // It links to artwork_id, not chapter_id
      const artIdNum = artworkId ? parseInt(artworkId) : null;

      if (artIdNum) {
        await dbArtworks.prepare(`
          INSERT INTO story_content (artwork_id, content_type, content_text, order_index, created_at)
          VALUES (?, 'text/markdown', ?, 1, datetime('now'))
        `).bind(artIdNum, content).run();
      } else {
        console.warn("Story created but no content saved (No Artwork ID provided).");
      }

      // 4. Redirect to the new story
      throw redirect(303, `/stories/${storySlug}/chapter-1`);

    } catch (e) {
      // If it's our redirect, throw it
      if (e.status === 303) throw e;
      
      console.error("Server Error creating story:", e);
      return { error: e.message };
    }
  }
};
