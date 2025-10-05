\set ON_ERROR_STOP on
SET search_path TO dw, public;

-- ВАЖНО: init/docker_init.sql делает \cd /docker-entrypoint-initdb.d
--        init/local_init.sql делает \cd .  (запуск из корня проекта)

-- ==================== STAGING ====================

DROP TABLE IF EXISTS _books_raw;
CREATE TABLE _books_raw (
  book_id                      INT,
  goodreads_book_id            INT,
  best_book_id                 INT,
  work_id                      INT,
  books_count                  INT,
  isbn                         TEXT,
  isbn13                       TEXT,
  authors                      TEXT,
  original_publication_year    NUMERIC,
  original_title               TEXT,
  title                        TEXT,
  language_code                TEXT,
  average_rating               NUMERIC,
  ratings_count                INT,
  work_ratings_count           INT,
  work_text_reviews_count      INT,
  ratings_1                    INT,
  ratings_2                    INT,
  ratings_3                    INT,
  ratings_4                    INT,
  ratings_5                    INT,
  image_url                    TEXT,
  small_image_url              TEXT
);
\copy _books_raw(book_id,goodreads_book_id,best_book_id,work_id,books_count,isbn,isbn13,authors,original_publication_year,original_title,title,language_code,average_rating,ratings_count,work_ratings_count,work_text_reviews_count,ratings_1,ratings_2,ratings_3,ratings_4,ratings_5,image_url,small_image_url) FROM 'seeds/books.csv' CSV HEADER;

DROP TABLE IF EXISTS _ratings;
CREATE TABLE _ratings(user_id INT, book_id INT, rating INT);
\copy _ratings(user_id,book_id,rating) FROM 'seeds/ratings.csv' CSV HEADER;

DROP TABLE IF EXISTS _tags;
CREATE TABLE _tags(tag_id INT, tag_name TEXT);
\copy _tags(tag_id,tag_name) FROM 'seeds/tags.csv' CSV HEADER;

DROP TABLE IF EXISTS _book_tags_raw;
CREATE TABLE _book_tags_raw(goodreads_book_id INT, tag_id INT, tag_count INT);
\copy _book_tags_raw(goodreads_book_id,tag_id,tag_count) FROM 'seeds/book_tags.csv' CSV HEADER;

DROP TABLE IF EXISTS _to_read;
CREATE TABLE _to_read(user_id INT, book_id INT);
\copy _to_read(user_id,book_id) FROM 'seeds/to_read.csv' CSV HEADER;

-- ==================== DIM LOADS ====================

INSERT INTO dim_books (
  book_id, title, authors, language_code, publication_year,
  avg_rating, ratings_count, meta
)
SELECT
  br.book_id,
  NULLIF(br.title,'')                               AS title,
  NULLIF(br.authors,'')                             AS authors,
  NULLIF(br.language_code,'')                       AS language_code,
  CASE
    WHEN br.original_publication_year IS NULL THEN NULL
    WHEN br.original_publication_year::text ~ '^[0-9]+(\.0+)?$' THEN br.original_publication_year::int
    ELSE NULL
  END                                               AS publication_year,
  NULLIF(br.average_rating::text,'')::numeric       AS avg_rating,
  br.ratings_count                                  AS ratings_count,
  jsonb_build_object(
    'isbn',      NULLIF(br.isbn,''),
    'isbn13',    NULLIF(br.isbn13,''),
    'publisher', NULL,
    'goodreads_book_id', NULLIF(br.goodreads_book_id::text,''),
    'best_book_id',      NULLIF(br.best_book_id::text,''),
    'work_id',           NULLIF(br.work_id::text,'')
  )::jsonb                                          AS meta
FROM _books_raw br
WHERE br.book_id IS NOT NULL
ON CONFLICT (book_id) DO NOTHING;

INSERT INTO dim_tags(tag_id, tag_name)
SELECT DISTINCT tag_id, tag_name
FROM _tags
WHERE tag_id IS NOT NULL
ON CONFLICT (tag_id) DO NOTHING;

INSERT INTO dim_users(user_id)
SELECT DISTINCT user_id FROM _ratings WHERE user_id IS NOT NULL
UNION
SELECT DISTINCT user_id FROM _to_read WHERE user_id IS NOT NULL
ON CONFLICT (user_id) DO NOTHING;

-- ==================== BRIDGE & FACTS ====================

-- map goodreads_book_id -> book_id через dim_books.meta
WITH map AS (
  SELECT
    book_id,
    NULLIF(meta->>'goodreads_book_id','')::int AS goodreads_book_id
  FROM dim_books
),
src AS (
  SELECT
    m.book_id,
    bt.tag_id,
    SUM(bt.tag_count) AS tag_count
  FROM _book_tags_raw bt
  JOIN map m ON m.goodreads_book_id = bt.goodreads_book_id
  WHERE bt.tag_id IS NOT NULL
  GROUP BY m.book_id, bt.tag_id
)
INSERT INTO bridge_book_tags (book_id, tag_id, tag_count)
SELECT book_id, tag_id, tag_count
FROM src
ON CONFLICT (book_id, tag_id) DO UPDATE
  SET tag_count = EXCLUDED.tag_count;

-- ratings
INSERT INTO fact_ratings (user_id, book_id, rating)
SELECT user_id, book_id, rating
FROM _ratings
WHERE user_id IS NOT NULL AND book_id IS NOT NULL AND rating BETWEEN 1 AND 5
ON CONFLICT (user_id, book_id) DO UPDATE
  SET rating = EXCLUDED.rating;

-- to_read
INSERT INTO fact_to_read (user_id, book_id)
SELECT user_id, book_id
FROM _to_read
WHERE user_id IS NOT NULL AND book_id IS NOT NULL
ON CONFLICT DO NOTHING;
