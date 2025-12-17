import { error } from '@sveltejs/kit';

/** @type {import('./$types').PageServerLoad} */
export async function load({ platform, params, locals, cookies }) {
  try {
    const { storySlug } = params;
    
    // Get language from cookie or default to es
    const preferredLanguage = cookies.get('preferredLanguage') || locals.locale || 'es';
    
    // Extract language code (es, en, fr)
    const langCode = preferredLanguage.split('-')[0];
    const langSuffix = ['es', 'en', 'fr'].includes(langCode) ? langCode : 'es';
    
    // Fetch story
    const story = await platform.env.DB_stories.prepare(`
      SELECT 
        id,
        slug,
        title_${langSuffix} AS title,
        description_${langSuffix} AS description,
        cover_image_url
      FROM stories
      WHERE slug = ? AND published = 1
    `)
      .bind(storySlug)
      .first();
    
    if (!story) {
      throw error(404, 'Story not found');
    }
    
    // Fetch chapters for this story
    const chaptersResult = await platform.env.DB_stories.prepare(`
      SELECT 
        slug,
        chapter_number,
        title_${langSuffix} AS title
      FROM story_chapters
      WHERE story_id = ? AND published = 1
      ORDER BY chapter_number ASC
    `)
      .bind(story.id)
      .all();
    
    return { 
      story, 
      chapters: chaptersResult.results || [],
      preferredLanguage 
    };
  } catch (err) {
    if (err.status === 404) throw err;
    console.error('Error loading story:', err);
    throw error(500, 'Failed to load story');
  }
}
