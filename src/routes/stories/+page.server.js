/** @type {import('./$types').PageServerLoad} */
export async function load({ platform, locals, cookies }) {
  try {
    // Get language from cookie or default to es-MX
    const preferredLanguage = cookies.get('preferredLanguage') || locals.locale || 'es-MX';
    
    // Extract language code (es, en, fr)
    const langSuffix = preferredLanguage.startsWith('es') ? 'es' :
                       preferredLanguage.startsWith('en') ? 'en' : 'fr';
    
    // Fetch all published stories
    const result = await platform.env.DB_stories.prepare(`
      SELECT 
        slug,
        title_${langSuffix} AS title,
        description_${langSuffix} AS description,
        cover_image_url
      FROM stories
      WHERE published = 1
      ORDER BY order_index ASC, created_at DESC
    `).all();
    
    return { 
      stories: result.results || [],
      preferredLanguage 
    };
  } catch (error) {
    console.error('Error loading stories:', error);
    return { 
      stories: [],
      preferredLanguage: 'es-MX',
      error: 'Failed to load stories'
    };
  }
}
