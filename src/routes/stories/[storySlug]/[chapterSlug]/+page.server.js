import { error } from '@sveltejs/kit';

/** @type {import('./$types').PageServerLoad} */
export async function load({ platform, params, locals, cookies }) {
  try {
    const { storySlug, chapterSlug } = params;
    
    // Get language from cookie or default to es-MX
    const preferredLanguage = cookies.get('preferredLanguage') || locals.locale || 'es-MX';
    
    // Extract language code (es, en, fr)
    const langCode = preferredLanguage.split('-')[0];
    const langSuffix = ['es', 'en', 'fr'].includes(langCode) ? langCode : 'es';
    
    // Fetch chapter with story info
    const chapter = await platform.env.DB_stories.prepare(`
      SELECT 
        story_chapters.slug,
        story_chapters.chapter_number,
        story_chapters.title_${langSuffix} AS title,
        story_chapters.content_${langSuffix} AS content,
        story_chapters.animation_url,
        stories.slug AS story_slug,
        stories.title_${langSuffix} AS story_title
      FROM story_chapters
      JOIN stories ON story_chapters.story_id = stories.id
      WHERE stories.slug = ? 
        AND story_chapters.slug = ?
        AND stories.published = 1
        AND story_chapters.published = 1
    `)
      .bind(storySlug, chapterSlug)
      .first();
    
    if (!chapter) {
      throw error(404, 'Chapter not found');
    }
    
    // Optionally fetch prev/next chapters for navigation
    const navigation = await platform.env.DB_stories.prepare(`
      SELECT 
        slug,
        chapter_number,
        title_${langSuffix} AS title
      FROM story_chapters
      WHERE story_id = (SELECT id FROM stories WHERE slug = ?)
        AND published = 1
        AND chapter_number IN (?, ?)
      ORDER BY chapter_number ASC
    `)
      .bind(storySlug, chapter.chapter_number - 1, chapter.chapter_number + 1)
      .all();
    
    const chapters = navigation.results || [];
    const prevChapter = chapters.find(c => c.chapter_number === chapter.chapter_number - 1);
    const nextChapter = chapters.find(c => c.chapter_number === chapter.chapter_number + 1);
    
    return { 
      chapter,
      prevChapter,
      nextChapter,
      preferredLanguage 
    };
  } catch (err) {
    if (err.status === 404) throw err;
    console.error('Error loading chapter:', err);
    throw error(500, 'Failed to load chapter');
  }
}
