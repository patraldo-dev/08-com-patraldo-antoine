/** @type {import('./$types').PageServerLoad} */
export async function load({ params, locals }) {
  const { storySlug, chapterSlug } = params;
  const { preferredLanguage } = locals;
  const langSuffix = preferredLanguage === 'es-MX' ? 'es' :
                     preferredLanguage === 'en-US' ? 'en' : 'fr';

  const chapter = await platform.env.DB_stories_stories.prepare(`
    SELECT 
      title_${langSuffix} AS title,
      content_${langSuffix} AS content,
      animation_url
    FROM story_chapters
    JOIN stories ON story_chapters.story_id = stories.id
    WHERE stories.slug = ? 
      AND story_chapters.slug = ?
      AND stories.published = 1
      AND story_chapters.published = 1
  `)
    .bind(storySlug, chapterSlug)
    .first();

  if (!chapter) throw error(404, 'Chapter not found');

  return { chapter, preferredLanguage };
}
