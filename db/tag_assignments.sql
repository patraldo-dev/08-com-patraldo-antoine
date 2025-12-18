-- tag_assignments.sql
-- Assign mood tags to artworks based on their characteristics

-- Gremelda - mysterious, surreal
INSERT INTO artwork_tags (artwork_id, tag_id) VALUES
(8, (SELECT id FROM tags WHERE name = 'mysterious')),
(8, (SELECT id FROM tags WHERE name = 'surreal'));

-- El Rey Azul - mysterious, calm
INSERT INTO artwork_tags (artwork_id, tag_id) VALUES
(9, (SELECT id FROM tags WHERE name = 'mysterious')),
(9, (SELECT id FROM tags WHERE name = 'calm'));

-- El Rey Verde - vibrant, energetic
INSERT INTO artwork_tags (artwork_id, tag_id) VALUES
(10, (SELECT id FROM tags WHERE name = 'vibrant')),
(10, (SELECT id FROM tags WHERE name = 'energetic'));

-- El Rey Amarillo - vibrant, playful
INSERT INTO artwork_tags (artwork_id, tag_id) VALUES
(11, (SELECT id FROM tags WHERE name = 'vibrant')),
(11, (SELECT id FROM tags WHERE name = 'playful'));

-- El Rey Castaño - mysterious, contemplative
INSERT INTO artwork_tags (artwork_id, tag_id) VALUES
(12, (SELECT id FROM tags WHERE name = 'mysterious')),
(12, (SELECT id FROM tags WHERE name = 'contemplative'));

-- El Rey Naranja - vibrant, energetic
INSERT INTO artwork_tags (artwork_id, tag_id) VALUES
(13, (SELECT id FROM tags WHERE name = 'vibrant')),
(13, (SELECT id FROM tags WHERE name = 'energetic'));

-- Guiona - mysterious, contemplative
INSERT INTO artwork_tags (artwork_id, tag_id) VALUES
(14, (SELECT id FROM tags WHERE name = 'mysterious')),
(14, (SELECT id FROM tags WHERE name = 'contemplative'));

-- Fashion - vibrant, playful
INSERT INTO artwork_tags (artwork_id, tag_id) VALUES
(15, (SELECT id FROM tags WHERE name = 'vibrant')),
(15, (SELECT id FROM tags WHERE name = 'playful'));

-- Blue Leafed Plant - calm, contemplative
INSERT INTO artwork_tags (artwork_id, tag_id) VALUES
(16, (SELECT id FROM tags WHERE name = 'calm')),
(16, (SELECT id FROM tags WHERE name = 'contemplative'));

-- Pinki - vibrant, playful
INSERT INTO artwork_tags (artwork_id, tag_id) VALUES
(17, (SELECT id FROM tags WHERE name = 'vibrant')),
(17, (SELECT id FROM tags WHERE name = 'playful'));

-- Rebeka - mysterious, surreal
INSERT INTO artwork_tags (artwork_id, tag_id) VALUES
(18, (SELECT id FROM tags WHERE name = 'mysterious')),
(18, (SELECT id FROM tags WHERE name = 'surreal'));

-- Hans - calm, contemplative
INSERT INTO artwork_tags (artwork_id, tag_id) VALUES
(19, (SELECT id FROM tags WHERE name = 'calm')),
(19, (SELECT id FROM tags WHERE name = 'contemplative'));

-- Miss B Thing - playful, surreal
INSERT INTO artwork_tags (artwork_id, tag_id) VALUES
(20, (SELECT id FROM tags WHERE name = 'playful')),
(20, (SELECT id FROM tags WHERE name = 'surreal'));

-- Radiana - mysterious, contemplative
INSERT INTO artwork_tags (artwork_id, tag_id) VALUES
(21, (SELECT id FROM tags WHERE name = 'mysterious')),
(21, (SELECT id FROM tags WHERE name = 'contemplative'));

-- Nocturnos Voladores - mysterious, surreal
INSERT INTO artwork_tags (artwork_id, tag_id) VALUES
(22, (SELECT id FROM tags WHERE name = 'mysterious')),
(22, (SELECT id FROM tags WHERE name = 'surreal'));

-- Muchos Amigos - playful, energetic
INSERT INTO artwork_tags (artwork_id, tag_id) VALUES
(23, (SELECT id FROM tags WHERE name = 'playful')),
(23, (SELECT id FROM tags WHERE name = 'energetic'));

-- Monstruo Café - playful, surreal
INSERT INTO artwork_tags (artwork_id, tag_id) VALUES
(24, (SELECT id FROM tags WHERE name = 'playful')),
(24, (SELECT id FROM tags WHERE name = 'surreal'));
