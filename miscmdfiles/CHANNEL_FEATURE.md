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
