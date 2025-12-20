// src/routes/sitemap.xml/+server.js
export async function GET({ locals }) {
  const baseUrl = 'https://antoine.patraldo.com';
  
  // Static pages with priorities
  const staticPages = [
    { url: '', priority: '1.0', changefreq: 'daily' },
    { url: 'collection', priority: '0.9', changefreq: 'weekly' },
    { url: 'cine', priority: '0.8', changefreq: 'weekly' },
    { url: 'cine/gallery', priority: '0.8', changefreq: 'weekly' },
    { url: 'stories', priority: '0.7', changefreq: 'weekly' },
    { url: 'tools', priority: '0.6', changefreq: 'monthly' },
    { url: 'tools/palettes', priority: '0.6', changefreq: 'weekly' },
    { url: 'tools/wallpapers', priority: '0.6', changefreq: 'weekly' },
    { url: 'tools/stickers', priority: '0.6', changefreq: 'weekly' },
  ];
  
  try {
    // Fetch all published artworks (both regular and cinematic)
    const artworks = await locals.platform.env.DB.prepare(
      `SELECT 
        id, 
        slug, 
        is_cinematic,
        updated_at,
        story_enabled
      FROM artworks 
      WHERE published = 1
      ORDER BY updated_at DESC`
    ).all();
    
    // Separate regular artworks and cinematic videos
    const regularArtworks = artworks.results.filter(a => !a.is_cinematic);
    const cinematicVideos = artworks.results.filter(a => a.is_cinematic);
    
    // Format date helper
    const formatDate = (timestamp) => {
      if (!timestamp) return new Date().toISOString().split('T')[0];
      return timestamp.split('T')[0];
    };
    
    // Build sitemap XML
    const sitemap = `<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
  ${staticPages.map(page => `
  <url>
    <loc>${baseUrl}/${page.url}</loc>
    <changefreq>${page.changefreq}</changefreq>
    <priority>${page.priority}</priority>
  </url>`).join('')}
  ${regularArtworks.map(artwork => `
  <url>
    <loc>${baseUrl}/#artwork-${artwork.id}</loc>
    <lastmod>${formatDate(artwork.updated_at)}</lastmod>
    <changefreq>monthly</changefreq>
    <priority>${artwork.story_enabled ? '0.85' : '0.8'}</priority>
  </url>`).join('')}
  ${cinematicVideos.map(video => `
  <url>
    <loc>${baseUrl}/cine/watch/${video.id}</loc>
    <lastmod>${formatDate(video.updated_at)}</lastmod>
    <changefreq>monthly</changefreq>
    <priority>0.75</priority>
  </url>`).join('')}
</urlset>`;
    
    return new Response(sitemap.trim(), {
      headers: {
        'Content-Type': 'application/xml; charset=utf-8',
        'Cache-Control': 'public, max-age=3600'
      }
    });
    
  } catch (error) {
    console.error('Sitemap generation error:', error);
    
    // Fallback to basic sitemap if DB query fails
    const basicSitemap = `<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
  ${staticPages.map(page => `
  <url>
    <loc>${baseUrl}/${page.url}</loc>
    <changefreq>${page.changefreq}</changefreq>
    <priority>${page.priority}</priority>
  </url>`).join('')}
</urlset>`;
    
    return new Response(basicSitemap.trim(), {
      headers: {
        'Content-Type': 'application/xml; charset=utf-8',
        'Cache-Control': 'public, max-age=3600'
      }
    });
  }
}
