#!/bin/bash

# Movie Channel - Integration with Existing i18n Setup
# Default language: es (Spanish)
# Uses flattened JSON structure
# Reuses existing LanguageSwitcherUniversal component

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_step() { echo -e "${BLUE}==>${NC} $1"; }
print_success() { echo -e "${GREEN}✓${NC} $1"; }
print_error() { echo -e "${RED}✗${NC} $1"; }
print_warning() { echo -e "${YELLOW}⚠${NC} $1"; }

integrate_feature() {
    echo -e "${BLUE}"
    echo "╔═══════════════════════════════════════════════╗"
    echo "║   Movie Channel - Existing Setup Integration ║"
    echo "║   Default: es | Uses: Flattened JSON         ║"
    echo "╚═══════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    if [ ! -f "svelte.config.js" ]; then
        print_error "Not in a SvelteKit project directory!"
        exit 1
    fi
    
    # Verify existing i18n structure
    if [ ! -f "src/lib/i18n/locales/es.json" ]; then
        print_warning "src/lib/i18n/locales/es.json not found. Will create it."
    fi
    
    # Install dependencies (if needed)
    print_step "Checking dependencies..."
    if ! npm list nanoid &> /dev/null; then
        npm install nanoid
        print_success "nanoid installed"
    else
        print_success "Dependencies already installed"
    fi
    
    # Create structure
    print_step "Creating directory structure..."
    mkdir -p src/lib/components/channel
    mkdir -p src/routes/api/channel/films
    mkdir -p migrations
    print_success "Directory structure created"
    
    # Create migration
    create_migration
    
    # Update translations
    update_translations
    
    # Create database helper
    create_db_helper
    
    # Create components
    create_components
    
    # Create routes
    create_routes
    
    create_readme
    
    print_success "Feature integration complete!"
    echo ""
    echo -e "${GREEN}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║      Movie Channel Integrated! 🎬             ║${NC}"
    echo -e "${GREEN}╚═══════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${BLUE}Next steps:${NC}"
    echo "1. Review updated translations in src/lib/i18n/locales/"
    echo "2. Run migration: wrangler d1 migrations apply <db> --remote"
    echo "3. Add CLOUDFLARE_STREAM_CUSTOMER_CODE to environment"
    echo "4. Default URL: /canal (Spanish)"
    echo "5. English: /en/channel"
    echo "6. French: /fr/chaîne"
    echo ""
    echo -e "${YELLOW}Note: Uses your existing LanguageSwitcherUniversal component${NC}"
}

create_migration() {
    print_step "Creating database migration..."
    TIMESTAMP=$(date +%s)
    
    cat > migrations/${TIMESTAMP}_movie_channel.sql << 'EOF'
-- Movie Channel Feature with i18n support

CREATE TABLE IF NOT EXISTS films (
  id TEXT PRIMARY KEY,
  title_es TEXT NOT NULL,
  title_en TEXT,
  title_fr TEXT,
  description_es TEXT,
  description_en TEXT,
  description_fr TEXT,
  stream_video_id TEXT NOT NULL,
  thumbnail_url TEXT,
  duration INTEGER,
  is_featured INTEGER DEFAULT 0,
  created_at INTEGER NOT NULL,
  view_count INTEGER DEFAULT 0
);

CREATE TABLE IF NOT EXISTS watch_history (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  film_id TEXT NOT NULL,
  watched_at INTEGER NOT NULL,
  progress INTEGER DEFAULT 0,
  FOREIGN KEY (film_id) REFERENCES films(id)
);

CREATE INDEX idx_watch_history_user ON watch_history(user_id);
CREATE INDEX idx_watch_history_film ON watch_history(film_id);
CREATE INDEX idx_films_featured ON films(is_featured);
EOF

    print_success "Migration created: migrations/${TIMESTAMP}_movie_channel.sql"
}

update_translations() {
    print_step "Adding channel translations to existing JSON files..."
    
    # Create temporary translation additions file
    cat > /tmp/channel_translations_es.json << 'EOF'
{
  "channel.hero.channelName": "Canal de Animación",
  "channel.hero.watchAgain": "Ver de nuevo",
  "channel.hero.duration": "Duración",
  "channel.hero.views": "vistas",
  "channel.hero.view": "vista",
  "channel.hero.noViews": "Sin vistas",
  "channel.loading": "Cargando...",
  "channel.error.noFilm": "No hay película destacada disponible",
  "channel.error.loadFailed": "Error al cargar el canal",
  "channel.nav.home": "Inicio",
  "channel.nav.library": "Biblioteca",
  "channel.nav.history": "Historial"
}
EOF

    cat > /tmp/channel_translations_en.json << 'EOF'
{
  "channel.hero.channelName": "Animation Channel",
  "channel.hero.watchAgain": "Watch Again",
  "channel.hero.duration": "Duration",
  "channel.hero.views": "views",
  "channel.hero.view": "view",
  "channel.hero.noViews": "No views",
  "channel.loading": "Loading...",
  "channel.error.noFilm": "No featured film available",
  "channel.error.loadFailed": "Failed to load channel",
  "channel.nav.home": "Home",
  "channel.nav.library": "Library",
  "channel.nav.history": "History"
}
EOF

    cat > /tmp/channel_translations_fr.json << 'EOF'
{
  "channel.hero.channelName": "Chaîne d'animation",
  "channel.hero.watchAgain": "Regarder à nouveau",
  "channel.hero.duration": "Durée",
  "channel.hero.views": "vues",
  "channel.hero.view": "vue",
  "channel.hero.noViews": "Aucune vue",
  "channel.loading": "Chargement...",
  "channel.error.noFilm": "Aucun film en vedette disponible",
  "channel.error.loadFailed": "Échec du chargement de la chaîne",
  "channel.nav.home": "Accueil",
  "channel.nav.library": "Bibliothèque",
  "channel.nav.history": "Historique"
}
EOF

    print_warning "Manual step required: Merge these translations into your existing JSON files:"
    print_warning "  - /tmp/channel_translations_es.json → src/lib/i18n/locales/es.json"
    print_warning "  - /tmp/channel_translations_en.json → src/lib/i18n/locales/en.json"
    print_warning "  - /tmp/channel_translations_fr.json → src/lib/i18n/locales/fr.json"
    
    # Attempt automatic merge if jq is available
    if command -v jq &> /dev/null; then
        print_step "jq detected - attempting automatic merge..."
        
        for lang in es en fr; do
            if [ -f "src/lib/i18n/locales/${lang}.json" ]; then
                jq -s '.[0] * .[1]' "src/lib/i18n/locales/${lang}.json" "/tmp/channel_translations_${lang}.json" > "/tmp/merged_${lang}.json"
                mv "/tmp/merged_${lang}.json" "src/lib/i18n/locales/${lang}.json"
                print_success "Merged translations into ${lang}.json"
            else
                cp "/tmp/channel_translations_${lang}.json" "src/lib/i18n/locales/${lang}.json"
                print_success "Created new ${lang}.json"
            fi
        done
    fi
}

create_db_helper() {
    print_step "Creating database helper..."
    
    cat > src/lib/server/channel-db.js << 'EOF'
import { nanoid } from 'nanoid';

/**
 * @typedef {Object} Film
 * @property {string} id
 * @property {string} title_es
 * @property {string} title_en
 * @property {string} title_fr
 * @property {string} description_es
 * @property {string} description_en
 * @property {string} description_fr
 * @property {string} stream_video_id
 * @property {string} thumbnail_url
 * @property {number} duration
 * @property {number} is_featured
 * @property {number} created_at
 * @property {number} view_count
 */

export class ChannelDatabase {
  /**
   * @param {import('@cloudflare/workers-types').D1Database} db
   */
  constructor(db) {
    this.db = db;
  }

  /**
   * Get localized film data based on locale
   * @param {Film} film
   * @param {string} locale - Locale code (es, en, fr)
   * @returns {Object} Localized film object
   */
  getLocalizedFilm(film, locale = 'es') {
    // Map full locale codes to language codes
    const lang = locale.split('-')[0];
    
    return {
      ...film,
      title: film[`title_${lang}`] || film.title_es,
      description: film[`description_${lang}`] || film.description_es
    };
  }

  /**
   * Get the featured film
   * @returns {Promise<Film | null>}
   */
  async getFeaturedFilm() {
    const result = await this.db
      .prepare('SELECT * FROM films WHERE is_featured = 1 ORDER BY created_at DESC LIMIT 1')
      .first();
    return result;
  }

  /**
   * Get film by ID
   * @param {string} id
   * @returns {Promise<Film | null>}
   */
  async getFilmById(id) {
    return await this.db
      .prepare('SELECT * FROM films WHERE id = ?')
      .bind(id)
      .first();
  }

  /**
   * Get all films
   * @returns {Promise<Film[]>}
   */
  async getAllFilms() {
    const result = await this.db
      .prepare('SELECT * FROM films ORDER BY created_at DESC')
      .all();
    return result.results;
  }

  /**
   * Create a new film
   * @param {Omit<Film, 'id' | 'created_at' | 'view_count'>} film
   * @returns {Promise<Film>}
   */
  async createFilm(film) {
    const id = nanoid();
    const created_at = Date.now();
    
    await this.db
      .prepare(
        `INSERT INTO films (id, title_es, title_en, title_fr, description_es, description_en, description_fr, 
         stream_video_id, thumbnail_url, duration, is_featured, created_at, view_count)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 0)`
      )
      .bind(
        id,
        film.title_es,
        film.title_en,
        film.title_fr,
        film.description_es,
        film.description_en,
        film.description_fr,
        film.stream_video_id,
        film.thumbnail_url,
        film.duration,
        film.is_featured,
        created_at
      )
      .run();

    return { ...film, id, created_at, view_count: 0 };
  }

  /**
   * Increment view count for a film
   * @param {string} filmId
   * @returns {Promise<void>}
   */
  async incrementViewCount(filmId) {
    await this.db
      .prepare('UPDATE films SET view_count = view_count + 1 WHERE id = ?')
      .bind(filmId)
      .run();
  }

  /**
   * Record watch history for a user
   * @param {string} userId
   * @param {string} filmId
   * @param {number} progress
   * @returns {Promise<void>}
   */
  async recordWatchHistory(userId, filmId, progress) {
    const id = nanoid();
    const watched_at = Date.now();

    await this.db
      .prepare(
        `INSERT INTO watch_history (id, user_id, film_id, watched_at, progress)
         VALUES (?, ?, ?, ?, ?)`
      )
      .bind(id, userId, filmId, watched_at, progress)
      .run();
  }

  /**
   * Get user's watch history
   * @param {string} userId
   * @param {number} limit
   * @returns {Promise<any[]>}
   */
  async getUserWatchHistory(userId, limit = 20) {
    const result = await this.db
      .prepare(
        `SELECT f.*, w.watched_at, w.progress
         FROM watch_history w
         JOIN films f ON w.film_id = f.id
         WHERE w.user_id = ?
         ORDER BY w.watched_at DESC
         LIMIT ?`
      )
      .bind(userId, limit)
      .all();
    return result.results;
  }
}
EOF

    print_success "Database helper created"
}

create_components() {
    print_step "Creating channel components..."
    
    # VideoPlayer component
    cat > src/lib/components/channel/VideoPlayer.svelte << 'EOF'
<script>
  /**
   * @typedef {Object} Props
   * @property {string} videoId - Cloudflare Stream video ID
   * @property {string} customerCode - Cloudflare Stream customer code
   * @property {boolean} [autoplay] - Autoplay video
   * @property {boolean} [muted] - Start muted
   */
  
  /** @type {Props} */
  let { videoId, customerCode, autoplay = true, muted = false } = $props();
  let isLoaded = $state(false);
</script>

<div class="video-wrapper">
  <iframe
    src={`https://customer-${customerCode}.cloudflarestream.com/${videoId}/iframe?autoplay=${autoplay}&muted=${muted}`}
    style="border: none; position: absolute; top: 0; left: 0; height: 100%; width: 100%;"
    allow="accelerometer; gyroscope; autoplay; encrypted-media; picture-in-picture;"
    allowfullscreen={true}
    onload={() => isLoaded = true}
    title="Video player"
  ></iframe>
  
  {#if !isLoaded}
    <div class="loading">
      <div class="spinner"></div>
    </div>
  {/if}
</div>

<style>
  .video-wrapper {
    position: relative;
    width: 100%;
    height: 100vh;
    background: #000;
  }
  
  .loading {
    position: absolute;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
    display: flex;
    align-items: center;
    justify-content: center;
    background: #000;
  }
  
  .spinner {
    width: 50px;
    height: 50px;
    border: 4px solid rgba(255, 255, 255, 0.1);
    border-top-color: #fff;
    border-radius: 50%;
    animation: spin 1s linear infinite;
  }
  
  @keyframes spin {
    to { transform: rotate(360deg); }
  }
</style>
EOF

    # HeroOverlay component - uses existing i18n
    cat > src/lib/components/channel/HeroOverlay.svelte << 'EOF'
<script>
  import { t } from '$lib/i18n';
  
  /**
   * @typedef {Object} Film
   * @property {string} title
   * @property {string} description
   * @property {number} duration
   * @property {number} view_count
   */
  
  /**
   * @typedef {Object} Props
   * @property {Film} film
   * @property {string} [locale] - Current locale for home link
   */
  
  /** @type {Props} */
  let { film, locale = 'es' } = $props();
  
  /**
   * Format duration in seconds to MM:SS
   * @param {number} seconds
   * @returns {string}
   */
  function formatDuration(seconds) {
    const mins = Math.floor(seconds / 60);
    const secs = seconds % 60;
    return `${mins}:${secs.toString().padStart(2, '0')}`;
  }
  
  /**
   * Format view count with proper pluralization
   * @param {number} count
   * @returns {string}
   */
  function formatViews(count) {
    if (count === 0) return $t('channel.hero.noViews');
    if (count === 1) return `1 ${$t('channel.hero.view')}`;
    return `${count} ${$t('channel.hero.views')}`;
  }
  
  /** @type {string} */
  let homeLink = $derived(locale === 'es' ? '/' : `/${locale}`);
</script>

<div class="hero-overlay">
  <div class="brand">
    <a href={homeLink} class="home-link">← {$t('channel.nav.home')}</a>
    <h1 class="channel-name">{$t('channel.hero.channelName')}</h1>
  </div>
  
  <div class="film-info">
    <h2 class="film-title">{film.title}</h2>
    <p class="film-description">{film.description}</p>
    <div class="metadata">
      <span class="duration">
        {$t('channel.hero.duration')}: {formatDuration(film.duration)}
      </span>
      <span class="views">
        {formatViews(film.view_count)}
      </span>
    </div>
  </div>
</div>

<style>
  .hero-overlay {
    position: fixed;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
    pointer-events: none;
    z-index: 10;
    background: linear-gradient(
      to top,
      rgba(0, 0, 0, 0.8) 0%,
      rgba(0, 0, 0, 0.4) 30%,
      transparent 50%
    );
  }
  
  .brand {
    position: absolute;
    top: 2rem;
    left: 2rem;
    pointer-events: auto;
  }
  
  .home-link {
    display: inline-block;
    color: #fff;
    text-decoration: none;
    margin-bottom: 1rem;
    opacity: 0.8;
    transition: opacity 0.2s;
    font-size: 0.95rem;
  }
  
  .home-link:hover {
    opacity: 1;
  }
  
  .channel-name {
    font-size: 1.5rem;
    font-weight: 700;
    color: #fff;
    text-shadow: 0 2px 8px rgba(0, 0, 0, 0.8);
    margin: 0;
  }
  
  .film-info {
    position: absolute;
    bottom: 4rem;
    left: 2rem;
    max-width: 600px;
    pointer-events: auto;
  }
  
  .film-title {
    font-size: 3rem;
    font-weight: 700;
    color: #fff;
    margin: 0 0 1rem;
    text-shadow: 0 2px 16px rgba(0, 0, 0, 0.9);
    line-height: 1.1;
  }
  
  .film-description {
    font-size: 1.1rem;
    color: #e0e0e0;
    margin: 0 0 1rem;
    text-shadow: 0 1px 8px rgba(0, 0, 0, 0.9);
    line-height: 1.5;
  }
  
  .metadata {
    display: flex;
    gap: 1.5rem;
    flex-wrap: wrap;
  }
  
  .duration, .views {
    color: #aaa;
    font-size: 0.9rem;
    text-shadow: 0 1px 4px rgba(0, 0, 0, 0.8);
  }
  
  @media (max-width: 768px) {
    .film-title {
      font-size: 2rem;
    }
    
    .film-info {
      left: 1rem;
      right: 1rem;
      bottom: 2rem;
    }
  }
</style>
EOF

    print_success "Components created (uses your existing i18n setup)"
}

create_routes() {
    print_step "Creating routes..."
    
    # Spanish route (default) - /canal
    mkdir -p src/routes/canal
    
    cat > src/routes/canal/+page.server.js << 'EOF'
import { ChannelDatabase } from '$lib/server/channel-db.js';
import { error } from '@sveltejs/kit';

/**
 * @type {import('./$types').PageServerLoad}
 */
export async function load({ platform, locals }) {
  if (!platform?.env?.DB) {
    throw error(500, 'Database not configured');
  }

  const db = new ChannelDatabase(platform.env.DB);
  const featuredFilm = await db.getFeaturedFilm();
  
  if (!featuredFilm) {
    throw error(404, 'No featured film available');
  }
  
  const locale = locals.locale || 'es';
  const localizedFilm = db.getLocalizedFilm(featuredFilm, locale);
  
  return {
    film: localizedFilm,
    customerCode: platform.env.CLOUDFLARE_STREAM_CUSTOMER_CODE || 'CUSTOMER_CODE_NOT_SET',
    locale: locale
  };
}
EOF

    cat > src/routes/canal/+page.svelte << 'EOF'
<script>
  import VideoPlayer from '$lib/components/channel/VideoPlayer.svelte';
  import HeroOverlay from '$lib/components/channel/HeroOverlay.svelte';
  import LanguageSwitcherUniversal from '$lib/components/ui/LanguageSwitcherUniversal.svelte';
  
  /**
   * @typedef {Object} PageData
   * @property {Object} film
   * @property {string} film.title
   * @property {string} film.description
   * @property {string} film.stream_video_id
   * @property {number} film.duration
   * @property {number} film.view_count
   * @property {string} customerCode
   * @property {string} locale
   */
  
  /** @type {{ data: PageData }} */
  let { data } = $props();
</script>

<svelte:head>
  <title>{data.film.title} - Canal de Animación</title>
  <meta name="description" content={data.film.description} />
</svelte:head>

<div class="channel-page">
  <div class="language-switcher-container">
    <LanguageSwitcherUniversal />
  </div>
  
  <VideoPlayer 
    videoId={data.film.stream_video_id}
    customerCode={data.customerCode}
    autoplay={true}
    muted={false}
  />
  
  <HeroOverlay film={data.film} locale={data.locale} />
</div>

<style>
  .channel-page {
    position: relative;
    width: 100%;
    height: 100vh;
    overflow: hidden;
    background: #000;
  }
  
  .language-switcher-container {
    position: fixed;
    top: 2rem;
    right: 2rem;
    z-index: 100;
    pointer-events: auto;
  }
</style>
EOF

    # English route - /en/channel
    mkdir -p src/routes/en/channel
    cp src/routes/canal/+page.server.js src/routes/en/channel/+page.server.js
    cp src/routes/canal/+page.svelte src/routes/en/channel/+page.svelte
    
    # French route - /fr/chaîne
    mkdir -p "src/routes/fr/chaîne"
    cp src/routes/canal/+page.server.js "src/routes/fr/chaîne/+page.server.js"
    cp src/routes/canal/+page.svelte "src/routes/fr/chaîne/+page.svelte"
    
    # API endpoint (language-agnostic)
    cat > src/routes/api/canal/films/+server.js << 'EOF'
import { json, error } from '@sveltejs/kit';
import { ChannelDatabase } from '$lib/server/channel-db.js';

/**
 * @type {import('./$types').RequestHandler}
 */
export async function GET({ platform, url }) {
  if (!platform?.env?.DB) {
    throw error(500, 'Database not configured');
  }

  try {
    const db = new ChannelDatabase(platform.env.DB);
    const locale = url.searchParams.get('locale') || 'es';
    const films = await db.getAllFilms();
    
    // Localize all films
    const localizedFilms = films.map(film => db.getLocalizedFilm(film, locale));
    
    return json({ films: localizedFilms });
  } catch (err) {
    console.error('Failed to fetch films:', err);
    throw error(500, 'Failed to fetch films');
  }
}
EOF

    print_success "Routes created (Spanish default at /canal)"
}

create_readme() {
    print_step "Creating documentation..."
    
    cat > CHANNEL_FEATURE.md << 'EOF'
# Movie Channel Feature

Integrated with your existing i18n setup. Default language: **Spanish (es)**.

## Features

✅ Uses your existing flattened JSON translations
✅ Integrates with your LanguageSwitcherUniversal component
✅ Svelte 5 runes throughout
✅ JSDoc type annotations
✅ Cloudflare Stream video player
✅ Multilingual film content in database

## Routes

- **Spanish (default)**: `/canal`
- **English**: `/en/channel`
- **French**: `/fr/chaîne`

## Translation Keys Added

The script adds these keys to your existing JSON files:

```json
{
  "channel.hero.channelName": "...",
  "channel.hero.duration": "...",
  "channel.hero.views": "...",
  "channel.nav.home": "...",
  "channel.loading": "...",
  "channel.error.noFilm": "..."
}
```

## Database Schema

Films table with localized content (Spanish primary):
- `title_es`, `title_en`, `title_fr`
- `description_es`, `description_en`, `description_fr`

## Components Created

- `src/lib/components/channel/VideoPlayer.svelte` - Cloudflare Stream player
- `src/lib/components/channel/HeroOverlay.svelte` - Film info overlay with i18n

## Adding a Featured Film

```bash
wrangler d1 execute <your-db-name> --command="
  INSERT INTO films (
    id, title_es, title_en, title_fr,
    description_es, description_en, description_fr,
    stream_video_id, thumbnail_url, duration, 
    is_featured, created_at, view_count
  ) VALUES (
    'film1',
    'Animación Asombrosa',
    'Amazing Animation',
    'Animation Incroyable',
    'Una historia maravillosa',
    'A wonderful story',
    'Une histoire merveilleuse',
    'YOUR_CLOUDFLARE_STREAM_VIDEO_ID',
    '',
    300,
    1,
    $(date +%s)000,
    0
  )
"
```

## Environment Variables

Add to `wrangler.jsonc`:

```jsonc
{
  "vars": {
    "CLOUDFLARE_STREAM_CUSTOMER_CODE": "your-customer-code-here"
  }
}
```

Get your customer code from: Cloudflare Dashboard → Stream → Settings

## File Structure

```
src/
├── lib/
│   ├── components/
│   │   └── channel/
│   │       ├── VideoPlayer.svelte
│   │       └── HeroOverlay.svelte
│   ├── server/
│   │   └── channel-db.js
│   └── i18n/
│       └── locales/
│           ├── es.json (updated)
│           ├── en.json (updated)
│           └── fr.json (updated)
└── routes/
    ├── canal/                    # Spanish (default)
    │   ├── +page.svelte
    │   ├── +page.server.js
    │   └── api/
    │       └── films/
    │           └── +server.js
    ├── en/
    │   └── channel/              # English
    └── fr/
        └── chaîne/               # French
```

## Next Steps

1. Review and merge translation additions
2. Run database migration
3. Upload video to Cloudflare Stream
4. Add featured film to database
5. Test at `/canal`

## Future Enhancements

- Film library page (`/biblioteca`)
- User watch history
- Categories and tags
- Search functionality
- Recommendations based on viewing history
- Continue watching feature
EOF

    print_success "Documentation created: CHANNEL_FEATURE.md"
}

integrate_feature
