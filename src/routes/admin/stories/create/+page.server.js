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

    // 1. GET BINDINGS
    const dbStories = platform?.env?.stories_db;
    const dbArtworks = platform?.env?.ARTWORKS_DB;

    // 2. SECURITY CHECK (Show error on screen if bindings missing)
    if (!dbStories) {
      return { error: 'Server Configuration Error: stories_db is not connected.' };
    }
    if (!dbArtworks) {
      return { error: 'Server Configuration Error: ARTWORKS_DB is not connected. (Check wrangler.json bindings)' };
    }

    try {
      const artIdNum = artworkId ? parseInt(artworkId) : null;

      // 3. CREATE STORY (stories_db)
      const storyResult = await dbStories.prepare(`
        INSERT INTO stories (title, slug, created_at, updated_at)
        VALUES (?, ?, datetime('now'), datetime('now'))
      `).bind(storyTitle, storySlug).run();

      const storyId = storyResult.meta.last_row_id;

      // 4. CREATE CHAPTER (stories_db)
      const chapterResult = await dbStories.prepare(`
        INSERT INTO story_chapters (story_id, title, slug, order_index, artwork_id, created_at, updated_at)
        VALUES (?, ?, 'chapter-1', 1, ?, datetime('now'), datetime('now'))
      `).bind(storyId, chapterTitle || 'Chapter 1', artIdNum).run();

      // 5. SAVE CONTENT (ARTWORKS_DB)
      if (artIdNum) {
        await dbArtworks.prepare(`
          INSERT INTO story_content (artwork_id, content_type, content_text, order_index, created_at)
          VALUES (?, 'text/markdown', ?, 1, datetime('now'))
        `).bind(artIdNum, content).run();
      } else {
        console.warn("Skipping content save: No Artwork ID provided.");
      }

      // 6. REDIRECT
      throw redirect(303, `/stories/${storySlug}/chapter-1`);

    } catch (e) {
      // Do not redirect if there is an error. Return the error to the form.
      console.error("Error saving story:", e);
      return { error: e.message };
    }
  }
};
