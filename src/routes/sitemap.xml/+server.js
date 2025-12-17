// src/routes/sitemap.xml/+server.js
export async function GET({ locals }) {
  const pages = [
    { url: '', priority: '1.0', changefreq: 'daily' },
    { url: 'collection', priority: '0.9', changefreq: 'weekly' },
    { url: 'cine', priority: '0.8', changefreq: 'weekly' },
    { url: 'cine/gallery', priority: '0.8', changefreq: 'weekly' },
    { url: 'stories', priority: '0.7', changefreq: 'weekly' },
    { url: 'tools', priority: '0.6', changefreq: 'monthly' },
    { url: 'tools/palettes', priority: '0.6', changefreq: 'weekly' },
    { url: 'tools/wallpapers', priority: '0.6', changefreq: 'weekly' },
  ];
  
  // Fetch dynamic artwork pages from your D1 database
  const artworks = await locals.platform.env.DB.prepare(
    'SELECT id, slug, updated_at FROM artworks WHERE published = 1'
  ).all();
  
  // Fetch cine videos
  const videos = await locals.platform.env.DB.prepare(
    'SELECT id, updated_at FROM films WHERE published = 1'
  ).all();
  
  const baseUrl = 'https://antoine.patraldo.com';
  
  const sitemap = `<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
  ${pages.map(page => `
  <url>
    <loc>${baseUrl}/${page.url}</loc>
    <changefreq>${page.changefreq}</changefreq>
    <priority>${page.priority}</priority>
  </url>`).join('')}
  ${artworks.results.map(artwork => `
  <url>
    <loc>${baseUrl}/#artwork-${artwork.id}</loc>
    <lastmod>${artwork.updated_at || new Date().toISOString().split('T')[0]}</lastmod>
    <changefreq>monthly</changefreq>
    <priority>0.8</priority>
  </url>`).join('')}
  ${videos.results.map(video => `
  <url>
    <loc>${baseUrl}/cine/watch/${video.id}</loc>
    <lastmod>${video.updated_at || new Date().toISOString().split('T')[0]}</lastmod>
    <changefreq>monthly</changefreq>
    <priority>0.7</priority>
  </url>`).join('')}
</urlset>`;
  
  return new Response(sitemap, {
    headers: {
      'Content-Type': 'application/xml',
      'Cache-Control': 'max-age=3600'
    }
  });
}
