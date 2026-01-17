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

    const dbStories = platform?.env?.stories_db;
    const dbArtworks = platform?.env?.ARTWORKS_DB;

    if (!dbStories || !dbArtworks) {
      return { error: 'Database connection unavailable (Missing Bindings)' };
    }

    try {
      const artIdNum = artworkId ? parseInt(artworkId) : null;

      // 1. Create the Story
      const storyResult = await dbStories.prepare(`
        INSERT INTO stories (title, slug, created_at, updated_at)
        VALUES (?, ?, datetime('now'), datetime('now'))
      `).bind(storyTitle, storySlug).run();

      const storyId = storyResult.meta.last_row_id;

      // 2. Create the Chapter (NOW INCLUDES ARTWORK_ID)
      const chapterResult = await dbStories.prepare(`
        INSERT INTO story_chapters (story_id, title, slug, order_index, artwork_id, created_at, updated_at)
        VALUES (?, ?, 'chapter-1', 1, ?, datetime('now'), datetime('now'))
      `).bind(storyId, chapterTitle || 'Chapter 1', artIdNum).run();

      // 3. Insert Content into ARTWORKS_DB
      if (artIdNum) {
        await dbArtworks.prepare(`
          INSERT INTO story_content (artwork_id, content_type, content_text, order_index, created_at)
          VALUES (?, 'text/markdown', ?, 1, datetime('now'))
        `).bind(artIdNum, content).run();
      }

      throw redirect(303, `/stories/${storySlug}/chapter-1`);

    } catch (e) {
      if (e.status === 303) throw e;
      console.error("Server Error creating story:", e);
      return { error: e.message };
    }
  }
};
