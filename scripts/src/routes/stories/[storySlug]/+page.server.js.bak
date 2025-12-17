/** @type {import('./$types').PageServerLoad} */
export async function load({ params, locals }) {
  const { storySlug } = params;
  const { preferredLanguage } = locals;
  const langSuffix = preferredLanguage === 'es-MX' ? 'es' :
                     preferredLanguage === 'en-US' ? 'en' : 'fr';

  // Fetch story
  const story = await env.DB.prepare(`
    SELECT 
      slug,
      title_${langSuffix} AS title,
      description_${langSuffix} AS description
    FROM stories
    WHERE slug = ? AND published = 1
  `)
    .bind(storySlug)
    .first();

  if (!story) throw error(404, 'Story not found');

  // Fetch chapters
  const chapters = await env.DB.prepare(`
    SELECT 
      slug,
      title_${langSuffix} AS title
    FROM story_chapters
    WHERE story_id = (SELECT id FROM stories WHERE slug = ?)
      AND published = 1
    ORDER BY chapter_number ASC
  `)
    .bind(storySlug)
    .all()
    .then(r => r.results || []);

  return { story, chapters, preferredLanguage };
}
