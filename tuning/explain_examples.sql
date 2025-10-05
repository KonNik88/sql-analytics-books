-- EXPLAIN/ANALYZE examples (before/after indexes) with BUFFERS
-- Usage:
--   psql -h localhost -U app -d appdb -f tuning/explain_examples.sql
-- Plans will be printed to stdout. Uncomment \o lines to store to files.

SET search_path TO dw, public;
SET work_mem = '64MB';
SET jit = off;  -- for more stable numbers in demo

\echo '--- 1) Top books quality: baseline matview scan ---'
EXPLAIN (ANALYZE, BUFFERS, VERBOSE)
SELECT *
FROM mv_top_books_quality
ORDER BY quality_score DESC
LIMIT 50;

\echo ''
\echo '--- 2) Tag leaderboard: join bridge -> tags (benefits from idx bridge_book_tags_by_tag) ---'
EXPLAIN (ANALYZE, BUFFERS, VERBOSE)
WITH by_tag AS (
  SELECT t.tag_name, bt.book_id, bt.tag_count
  FROM bridge_book_tags bt
  JOIN dim_tags t USING(tag_id)
)
SELECT tag_name, book_id, tag_count
FROM (
  SELECT tag_name, book_id, tag_count,
         DENSE_RANK() OVER (PARTITION BY tag_name ORDER BY tag_count DESC) AS rnk
  FROM by_tag
) r
WHERE rnk <= 5
ORDER BY tag_name, rnk;

\echo ''
\echo '--- 3) FTS demo plan: GIN on to_tsvector(title||authors) ---'
EXPLAIN (ANALYZE, BUFFERS, VERBOSE)
SELECT book_id, title
FROM dim_books
WHERE to_tsvector('simple', coalesce(title,'') || ' ' || coalesce(authors,''))
      @@ plainto_tsquery('simple', 'stranger')
LIMIT 20;

\echo ''
\echo '--- 4) Trigram fuzzy demo plan: GIN (pg_trgm) on title ---'
EXPLAIN (ANALYZE, BUFFERS, VERBOSE)
SELECT book_id, title
FROM dim_books
WHERE title % 'Stragner'
ORDER BY similarity(title, 'Stragner') DESC
LIMIT 20;

-- To save a plan to a file, uncomment and rerun:
-- \o tuning/plan_top_books_quality.txt
-- EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM mv_top_books_quality ORDER BY quality_score DESC LIMIT 50;
-- \o
