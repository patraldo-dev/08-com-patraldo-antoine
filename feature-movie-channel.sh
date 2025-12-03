#!/bin/bash

# Movie Channel - Integration Following Existing Structure
# API routes: src/routes/api/canal/
# Page routes: src/routes/canal/

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
    echo "║   Movie Channel - Correct Structure          ║"
    echo "║   API: routes/api/canal/                     ║"
    echo "║   Pages: routes/canal/                       ║"
    echo "╚═══════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    if [ ! -f "svelte.config.js" ]; then
        print_error "Not in a SvelteKit project directory!"
        exit 1
    fi
    
    # Create feature branch
    read -p "Create new feature branch? (y/n): " CREATE_BRANCH
    if [ "$CREATE_BRANCH" = "y" ]; then
        read -p "Enter branch name (default: feature/movie-channel): " BRANCH_NAME
        BRANCH_NAME=${BRANCH_NAME:-feature/movie-channel}
        git checkout -b "$BRANCH_NAME"
        print_success "Branch created: $BRANCH_NAME"
    fi
    
    # Install dependencies
    print_step "Checking dependencies..."
    if ! npm list nanoid &> /dev/null; then
        npm install nanoid
        print_success "nanoid installed"
    else
        print_success "Dependencies already installed"
    fi
    
    # Create structure
    print_step "Creating directory structure..."
    mkdir -p src/lib/components/canal
    mkdir -p src/routes/api/canal
    mkdir -p src/routes/canal/film/[id]
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
    
    # Create API routes
    create_api_routes
    
    # Create page routes
    create_page_routes
    
    create_readme
    
    print_success "Feature integration complete!"
    echo ""
    echo -e "${GREEN}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║      Movie Channel Integrated! 🎬             ║${NC}"
    echo -e "${GREEN}╚═══════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${BLUE}Structure created:${NC}"
    echo "  src/routes/canal/              (page routes)"
    echo "  src/routes/api/canal/          (API routes)"
    echo "  src/lib/components/canal/      (components)"
    echo ""
    echo -e "${BLUE}Next steps:${NC}"
    echo "1. Review translations in src/lib/i18n/locales/"
    echo "2. Run: wrangler d1 migrations apply <db> --remote"
    echo "3. Add CLOUDFLARE_STREAM_CUSTOMER_CODE to wrangler.jsonc"
    echo "4. Visit: /canal (works in all languages)"
}

create_migration() {
    print_step "Creating database migration..."
    TIMESTAMP=$(date +%s)
    
    cat > "migrations/${TIMESTAMP}_canal.sql" << 'EOF'
-- Canal (Movie Channel) Feature with i18n support
-- Default language: Spanish (es)

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

    print_success "Migration created: migrations/${TIMESTAMP}_canal.sql"
}

update_translations() {
    print_step "Adding canal translations..."
    
    # Spanish translations
    cat > /tmp/canal_translations_es.json << 'EOF'
{
  "canal.hero.channelName": "Canal de Animación",
  "canal.hero.watchAgain": "Ver de nuevo",
  "canal.hero.duration": "Duración",
  "canal.hero.views": "vistas",
  "canal.hero.view": "vista",
  "canal.hero.noViews": "Sin vistas",
  "canal.loading": "Cargando...",
  "canal.error.noFilm": "No hay película destacada disponible",
  "canal.error.loadFailed": "Error al cargar el canal",
  "canal.nav.home": "Inicio",
  "canal.nav.library": "Biblioteca",
  "canal.nav.history": "Historial"
}
EOF

    # English translations
    cat > /tmp/canal_translations_en.json << 'EOF'
{
  "canal.hero.channelName": "Animation Channel",
  "canal.hero.watchAgain": "Watch Again",
  "canal.hero.duration": "Duration",
  "canal.hero.views": "views",
  "canal.hero.view": "view",
  "canal.hero.noViews": "No views",
  "canal.loading": "Loading...",
  "canal.error.noFilm": "No featured film available",
  "canal.error.loadFailed": "Failed to load channel",
  "canal.nav.home": "Home",
  "canal.nav.library": "Library",
  "canal.nav.history": "History"
}
EOF

    # French translations
    cat > /tmp/canal_translations_fr.json << 'EOF'
{
  "canal.hero.channelName": "Chaîne d'animation",
  "canal.hero.watchAgain": "Regarder à nouveau",
  "canal.hero.duration": "Durée",
  "canal.hero.views": "vues",
  "canal.hero.view": "vue",
  "canal.hero.noViews": "Aucune vue",
  "canal.loading": "Chargement...",
  "canal.error.noFilm": "Aucun film en vedette disponible",
  "canal.error.loadFailed": "Échec du chargement de la chaîne",
  "canal.nav.home": "Accueil",
  "canal.nav.library": "Bibliothèque",
  "canal.nav.history": "Historique"
}
EOF

    if command -v jq &> /dev/null; then
        print_step "Merging translations with jq..."
        for lang in es en fr; do
            if [ -f "src/lib/i18n/locales/${lang}.json" ]; then
                jq -s '.[0] * .[1]' "src/lib/i18n/locales/${lang}.json" "/tmp/canal_translations_${lang}.json" > "/tmp/merged_${lang}.json"
                mv "/tmp/merged_${lang}.json" "src/lib/i18n/locales/${lang}.json"
                print_success "Merged translations into ${lang}.json"
            else
                cp "/tmp/canal_translations_${lang}.json" "src/lib/i18n/locales/${lang}.json"
                print_success "Created ${lang}.json"
            fi
        done
    else
        print_warning "jq not found. Merge these files manually:"
        echo "  /tmp/canal_translations_*.json → src/lib/i18n/locales/"
    fi
}

create_db_helper() {
    print_step "Creating database helper..."
    
    cat > src/lib/server/canal-db.js << 'EOF'
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

/**
 * @typedef {Object} LocalizedFilm
 * @property {string} id
 * @property {string} title
 * @property {string} description
 * @property {string} stream_video_id
 * @property {string} thumbnail_url
 * @property {number} duration
 * @property {number} is_featured
 * @property {number} created_at
 * @property {number} view_count
 */

export class CanalDatabase {
  /**
   * @param {import('@cloudflare/workers-types').D1Database} db
   */
  constructor(db) {
    this.db = db;
  }

  /**
   * Get localized film data
   * @param {Film} film
   * @param {string} locale - es, en, fr (or es-MX, en-US, fr-CA)
   * @returns {LocalizedFilm}
   */
  getLocalizedFilm(film, locale = 'es') {
    const lang = locale.split('-')[0];
    
    return {
      id: film.id,
      title: film[`title_${lang}`] || film.title_es,
      description: film[`description_${lang}`] || film.description_es,
      stream_video_id: film.stream_video_id,
      thumbnail_url: film.thumbnail_url,
      duration: film.duration,
      is_featured: film.is_featured,
      created_at: film.created_at,
      view_count: film.view_count
    };
  }

  /**
   * @returns {Promise<Film | null>}
   */
  async getFeaturedFilm() {
    return await this.db
      .prepare('SELECT * FROM films WHERE is_featured = 1 ORDER BY created_at DESC LIMIT 1')
      .first();
  }

  /**
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
   * @returns {Promise<Film[]>}
   */
  async getAllFilms() {
    const result = await this.db
      .prepare('SELECT * FROM films ORDER BY created_at DESC')
      .all();
    return result.results;
  }

  /**
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
        'INSERT INTO watch_history (id, user_id, film_id, watched_at, progress) VALUES (?, ?, ?, ?, ?)'
      )
      .bind(id, userId, filmId, watched_at, progress)
      .run();
  }

  /**
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

    print_success "Database helper created: src/lib/server/canal-db.js"
}

create_components() {
    print_step "Creating components..."
    
    # VideoPlayer
    cat > src/lib/components/canal/VideoPlayer.svelte << 'EOF'
<script>
  /**
   * @typedef {Object} Props
   * @property {string} videoId
   * @property {string} customerCode
   * @property {boolean} [autoplay]
   * @property {boolean} [muted]
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
    z-index: 5;
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

    # HeroOverlay
    cat > src/lib/components/canal/HeroOverlay.svelte << 'EOF'
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
   */
  
  /** @type {Props} */
  let { film } = $props();
  
  /**
   * @param {number} seconds
   * @returns {string}
   */
  function formatDuration(seconds) {
    const mins = Math.floor(seconds / 60);
    const secs = seconds % 60;
    return `${mins}:${secs.toString().padStart(2, '0')}`;
  }
  
  /**
   * @param {number} count
   * @returns {string}
   */
  function formatViews(count) {
    if (count === 0) return $t('canal.hero.noViews');
    if (count === 1) return `1 ${$t('canal.hero.view')}`;
    return `${count} ${$t('canal.hero.views')}`;
  }
</script>

<div class="hero-overlay">
  <div class="brand">
    <a href="/" class="home-link">← {$t('canal.nav.home')}</a>
    <h1 class="channel-name">{$t('canal.hero.channelName')}</h1>
  </div>
  
  <div class="film-info">
    <h2 class="film-title">{film.title}</h2>
    <p class="film-description">{film.description}</p>
    <div class="metadata">
      <span class="duration">
        {$t('canal.hero.duration')}: {formatDuration(film.duration)}
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
    .brand {
      top: 1rem;
      left: 1rem;
    }
    
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

    print_success "Components created in src/lib/components/canal/"
}

create_api_routes() {
    print_step "Creating API routes..."
    
    # API: Get all films
    cat > src/routes/api/canal/+server.js << 'EOF'
import { json, error } from '@sveltejs/kit';
import { CanalDatabase } from '$lib/server/canal-db.js';

/**
 * @type {import('./$types').RequestHandler}
 */
export async function GET({ platform, locals, url }) {
  if (!platform?.env?.DB) {
    throw error(500, 'Database not configured');
  }

  try {
    const db = new CanalDatabase(platform.env.DB);
    const locale = locals.locale || url.searchParams.get('locale') || 'es';
    const films = await db.getAllFilms();
    
    const localizedFilms = films.map(film => db.getLocalizedFilm(film, locale));
    
    return json({ films: localizedFilms });
  } catch (err) {
    console.error('Failed to fetch films:', err);
    throw error(500, 'Failed to fetch films');
  }
}
EOF

    print_success "API routes created in src/routes/api/canal/"
}

create_page_routes() {
    print_step "Creating page routes..."
    
    # Main canal page server
    cat > src/routes/canal/+page.server.js << 'EOF'
import { CanalDatabase } from '$lib/server/canal-db.js';
import { error } from '@sveltejs/kit';

/**
 * @type {import('./$types').PageServerLoad}
 */
export async function load({ platform, locals }) {
  if (!platform?.env?.DB) {
    throw error(500, 'Database not configured');
  }

  const db = new CanalDatabase(platform.env.DB);
  const featuredFilm = await db.getFeaturedFilm();
  
  if (!featuredFilm) {
    throw error(404, 'No featured film available');
  }
  
  const locale = locals.locale || 'es';
  const localizedFilm = db.getLocalizedFilm(featuredFilm, locale);
  
  return {
    film: localizedFilm,
    customerCode: platform.env.CLOUDFLARE_STREAM_CUSTOMER_CODE || ''
  };
}
EOF

    # Main canal page
    cat > src/routes/canal/+page.svelte << 'EOF'
<script>
  import VideoPlayer from '$lib/components/canal/VideoPlayer.svelte';
  import HeroOverlay from '$lib/components/canal/HeroOverlay.svelte';
  import LanguageSwitcherUniversal from '$lib/components/ui/LanguageSwitcherUniversal.svelte';
  
  /** @type {{ data: any }} */
  let { data } = $props();
</script>

<svelte:head>
  <title>{data.film.title}</title>
  <meta name="description" content={data.film.description} />
</svelte:head>

<div class="canal-page">
  <div class="language-switcher-container">
    <LanguageSwitcherUniversal />
  </div>
  
  <VideoPlayer 
    videoId={data.film.stream_video_id}
    customerCode={data.customerCode}
    autoplay={true}
    muted={false}
  />
  
  <HeroOverlay film={data.film} />
</div>

<style>
  .canal-page {
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
  }
  
  @media (max-width: 768px) {
    .language-switcher-container {
      top: 1rem;
      right: 1rem;
    }
  }
</style>
EOF

    # Individual film page server
    cat > src/routes/canal/film/[id]/+page.server.js << 'EOF'
import { CanalDatabase } from '$lib/server/canal-db.js';
import { error } from '@sveltejs/kit';

/**
 * @type {import('./$types').PageServerLoad}
 */
export async function load({ platform, locals, params }) {
  if (!platform?.env?.DB) {
    throw error(500, 'Database not configured');
  }

  const db = new CanalDatabase(platform.env.DB);
  const film = await db.getFilmById(params.id);
  
  if (!film) {
    throw error(404, 'Film not found');
  }
  
  const locale = locals.locale || 'es';
  const localizedFilm = db.getLocalizedFilm(film, locale);
  
  return {
    film: localizedFilm,
    customerCode: platform.env.CLOUDFLARE_STREAM_CUSTOMER_CODE || ''
  };
}
EOF

    # Individual film page
    cat > src/routes/canal/film/[id]/+page.svelte << 'EOF'
<script>
  import VideoPlayer from '$lib/components/canal/VideoPlayer.svelte';
  import HeroOverlay from '$lib/components/canal/HeroOverlay.svelte';
  import LanguageSwitcherUniversal from '$lib/components/ui/LanguageSwitcherUniversal.svelte';
  
  /** @type {{ data: any }} */
  let { data } = $props();
</script>

<svelte:head>
  <title>{data.film.title}</title>
  <meta name="description" content={data.film.description} />
</svelte:head>

<div class="canal-page">
  <div class="language-switcher-container">
    <LanguageSwitcherUniversal />
  </div>
  
  <VideoPlayer 
    videoId={data.film.stream_video_id}
    customerCode={data.customerCode}
    autoplay={true}
    muted={false}
  />
  
  <HeroOverlay film={data.film} />
</div>

<style>
  .canal-page {
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
  }
</style>
EOF

    print_success "Page routes created in src/routes/canal/"
}

create_readme() {
    cat > CANAL_FEATURE.md << 'EOF'
# Canal (Movie Channel) Feature

## Structure

Following your existing patterns:

```
src/
├── routes/
│   ├── api/
│   │   └── canal/
│   │       └── +server.js          (GET all films)
│   └── canal/
│       ├── +page.svelte            (featured film)
│       ├── +page.server.js
│       └── film/
│           └── [id]/
│               ├── +page.svelte    (individual film)
│               └── +page.server.js
└── lib/
    ├── components/
    │   └── canal/
    │       ├── VideoPlayer.svelte
    │       └── HeroOverlay.svelte
    └── server/
        └── canal-db.js
```

## Routes

- `/canal` - Featured film (works in all languages)
- `/canal/film/[id]` - Individual film
- `/api/canal` - API to get all films

## Setup

1. Run migration:
   ```bash
   wrangler d1 migrations apply <your-db> --remote
   ```

2. Add to wrangler.jsonc:
   ```jsonc
   {
     "vars": {
       "CLOUDFLARE_STREAM_CUSTOMER_CODE": "your-code"
     }
   }
   ```

3. Add a film:
   ```bash
   wrangler d1 execute <db> --command="
     INSERT INTO films (
       id, title_es, title_en, title_fr,
       description_es, description_en, description_fr,
       stream_video_id, thumbnail_url, duration,
       is_featured, created_at, view_count
     ) VALUES (
       'film1',
       'Mi Primera Animación',
       'My First Animation',
       'Ma Première Animation',
       'Una historia increíble',
       'An amazing story',
       'Une histoire incroyable',
       'YOUR_STREAM_VIDEO_ID',
       '', 300, 1, $(date +%s)000, 0
     )
   "
   ```

4. Visit `/canal`
EOF

    print_success "Documentation created: CANAL_FEATURE.md"
}

integrate_feature
