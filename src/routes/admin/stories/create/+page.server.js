import { error, redirect } from '@sveltejs/kit';

export const actions = {
  default: async ({ request, platform }) => {
    const formData = await request.formData();
    const storyTitle = formData.get('title');
    const storySlug = formData.get('slug');
    const chapterTitle = formData.get('chapterTitle');
    const content = formData.get('content'); // The Markdown content
    const artworkId = formData.get('artworkId'); // Optional: Link to an artwork if this is a script for it

    const dbStories = platform?.env?.stories_db;

    if (!dbStories) {
      return { error: 'Stories DB not connected' };
    }

    try {
      // 1. Create the Story
      const storyResult = await dbStories.prepare(`
        INSERT INTO stories (title, slug, created_at, updated_at)
        VALUES (?, ?, datetime('now'), datetime('now'))
      `).bind(storyTitle, storySlug).run();

      const storyId = storyResult.meta.last_row_id;

      // 2. Create the Chapter (Linking to Story)
      const chapterResult = await dbStories.prepare(`
        INSERT INTO story_chapters (story_id, title, slug, order_index, created_at, updated_at)
        VALUES (?, ?, 'chapter-1', 1, datetime('now'), datetime('now'))
      `).bind(storyId, chapterTitle || 'Chapter 1').run();

      const chapterId = chapterResult.meta.last_row_id;

      // 3. Create the Content Block (Linking to Chapter)
      // If it's a movie script, you might want to link it to the specific artwork
      // We convert the 'artworkId' string to a number if it exists
      const artIdNum = artworkId ? parseInt(artworkId) : null;

      await dbStories.prepare(`
        INSERT INTO story_content (chapter_id, artwork_id, content_type, content_text, order_index, created_at)
        VALUES (?, ?, 'text/markdown', ?, 1, datetime('now'))
      `).bind(chapterId, artIdNum, content).run();

      // 4. (Optional) Update Artwork if linked, to show it has a story
      // You might want to update the `ARTWORKS_DB` here if you want the artwork card to show "Read Script"
      
      throw redirect(303, `/stories/${storySlug}/chapter-1`);

    } catch (e) {
      // Don't redirect on error, return it to the form
      if (e.status === 303) throw e; // This is our redirect, let it through
      console.error(e);
      return { error: e.message, title: storyTitle, slug: storySlug, content };
    }
  }
};
