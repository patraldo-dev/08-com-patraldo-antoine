#!/bin/bash
# scripts/scaffold-stories.sh

set -e

echo "🏗️  Creating stories scaffolding..."

# 1. Create directory structure
mkdir -p src/routes/stories/{[storySlug],[storySlug]/[chapterSlug]}

# 2. Create /stories/+page.svelte
cat > src/routes/stories/+page.svelte << 'EOF'
<script>
  let { data } = $props();
  const { stories, lang } = data;
</script>

<svelte:head>
  <title>Historias</title>
</svelte:head>

<div class="layout">
  <h1>Historias</h1>
  <ul>
    {#each stories as story}
      <li><a href="/stories/{story.slug}">{story.title}</a></li>
    {/each}
  </ul>
</div>
EOF

# 3. Create /stories/+page.server.js
cat > src/routes/stories/+page.server.js << 'EOF'
/** @type {import('./$types').PageServerLoad} */
export async function load({ locals }) {
  const { preferredLanguage } = locals;
  const langSuffix = preferredLanguage === 'es-MX' ? 'es' :
                     preferredLanguage === 'en-US' ? 'en' : 'fr';

  // Fetch all published stories, ordered
  const stories = await env.DB.prepare(`
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
EOF

# 4. Create /stories/[storySlug]/+page.svelte
cat > src/routes/stories/[storySlug]/+page.svelte << 'EOF'
<script>
  let { data } = $props();
  const { story, chapters, lang } = data;
</script>

<svelte:head>
  <title>{story.title}</title>
</svelte:head>

<div class="layout">
  <h1>{story.title}</h1>
  <p>{story.description}</p>
  
  <h2>Capítulos</h2>
  <ul>
    {#each chapters as chapter}
      <li><a href="/stories/{story.slug}/{chapter.slug}">{chapter.title}</a></li>
    {/each}
  </ul>
</div>
EOF

# 5. Create /stories/[storySlug]/+page.server.js
cat > src/routes/stories/[storySlug]/+page.server.js << 'EOF'
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
EOF

# 6. Create /stories/[storySlug]/[chapterSlug]/+page.svelte
cat > src/routes/stories/[storySlug]/[chapterSlug]/+page.svelte << 'EOF'
<script>
  let { data } = $props();
  const { chapter, lang } = data;
</script>

<svelte:head>
  <title>{chapter.title}</title>
</script>

<div class="layout">
  <h1>{chapter.title}</h1>
  <div>{@html chapter.content}</div>
  
  {#if chapter.animation_url}
    <div class="video-wrapper">
      <iframe
        src={chapter.animation_url}
        title={chapter.title}
        allow="autoplay; fullscreen"
        allowfullscreen
      ></iframe>
    </div>
  {/if}
</div>

<style>
  .video-wrapper {
    margin: 2rem 0;
    aspect-ratio: 16/9;
    width: 100%;
  }
  .video-wrapper iframe {
    width: 100%;
    height: 100%;
    border: none;
    border-radius: 8px;
  }
</style>
EOF

# 7. Create /stories/[storySlug]/[chapterSlug]/+page.server.js
cat > src/routes/stories/[storySlug]/[chapterSlug]/+page.server.js << 'EOF'
/** @type {import('./$types').PageServerLoad} */
export async function load({ params, locals }) {
  const { storySlug, chapterSlug } = params;
  const { preferredLanguage } = locals;
  const langSuffix = preferredLanguage === 'es-MX' ? 'es' :
                     preferredLanguage === 'en-US' ? 'en' : 'fr';

  const chapter = await env.DB.prepare(`
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
EOF

# 8. Create sample JSON for static UI (optional)
mkdir -p src/lib/locales/{es-MX,en-US,fr-CA}/pages
cat > src/lib/locales/es-MX/pages/stories.json << 'EOF'
{
  "title": "Historias",
  "intro": "Narrativas visuales interactivas"
}
EOF

cat > src/lib/locales/en-US/pages/stories.json << 'EOF'
{
  "title": "Stories",
  "intro": "Interactive visual narratives"
}
EOF

cat > src/lib/locales/fr-CA/pages/stories.json << 'EOF'
{
  "title": "Histoires",
  "intro": "Récits visuels interactifs"
}
EOF

# 9. Add loader to translations.js (append if not exists)
if ! grep -q "pages.stories.*routes.*\[\'/stories\'\]" src/lib/translations.js; then
  awk '/\/\/ ───────────────────────────────────────/{p=1} p && /loaders: \[/{print; print "    // ───────────────────────────────────────"; print "    // STORIES INDEX PAGE"; print "    // ───────────────────────────────────────"; print "    { locale: \"es-MX\", key: \"pages.stories\", routes: [\"/stories\"], loader: () => import(\"./locales/es-MX/pages/stories.json\") },"; print "    { locale: \"en-US\", key: \"pages.stories\", routes: [\"/stories\"], loader: () => import(\"./locales/en-US/pages/stories.json\") },"; print "    { locale: \"fr-CA\", key: \"pages.stories\", routes: [\"/stories\"], loader: () => import(\"./locales/fr-CA/pages/stories.json\") },"; p=0; next} {print}' src/lib/translations.js > /tmp/translations.js && mv /tmp/translations.js src/lib/translations.js
fi

echo "✅ Stories scaffolding created!"
echo "👉 Next steps:"
echo "  1. Deploy to Cloudflare to test"
echo "  2. Insert sample data into your D1 database"
echo "  3. Visit /stories to see your stories"
