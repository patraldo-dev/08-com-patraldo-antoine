# Add a test film to your database
npx wrangler d1 execute artist-portfolio-db --command="
  INSERT INTO films (
    id, title_es, title_en, title_fr,
    description_es, description_en, description_fr,
    stream_video_id, thumbnail_url, duration,
    is_featured, created_at, view_count
  ) VALUES (
    'test-film-1',
    'Película de Prueba',
    'Test Film',
    'Film de Test',
    'Una película de prueba para el canal',
    'A test film for the channel',
    'Un film de test pour la chaîne',
    'YOUR_CLOUDFLARE_STREAM_VIDEO_ID',
    '',
    180,
    1,
    $(date +%s)000,
    0
  )
" --remote
