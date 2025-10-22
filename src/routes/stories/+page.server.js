/** @type {import('./$types').PageServerLoad} */
export async function load({ platform,  locals }) {
  const { preferredLanguage } = locals;
  const langSuffix = preferredLanguage === 'es-MX' ? 'es' :
                     preferredLanguage === 'en-US' ? 'en' : 'fr';

  // Fetch all published stories, ordered
  const stories = await platform.platform.env.DB_stories_stories_stories_stories.prepare(`
    SELECT 
      slug,
      title_${langSuffix} AS title
    FROM stories
    WHERE published = 1
    ORDER BY order_index ASC
  `)
    .all()
    .then(r => r.results || []);

  return { stories, preferredLanguage };
}
