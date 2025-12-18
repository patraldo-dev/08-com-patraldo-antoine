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
