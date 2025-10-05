SET search_path TO dw, public;
SET jit = off;

\echo '=== BEFORE adding indexes (if you want to test, drop them first) ==='
-- Example plans:
EXPLAIN (ANALYZE, BUFFERS)
SELECT book_id, title
FROM dim_books
WHERE to_tsvector('simple', coalesce(title,'') || ' ' || coalesce(authors,''))
      @@ plainto_tsquery('simple', 'stranger')
LIMIT 20;

\echo ''
\echo '=== Ensure indexes exist (playbook) ==='
\i tuning/indexes_playbook.sql

\echo ''
\echo '=== AFTER indexes ==='
EXPLAIN (ANALYZE, BUFFERS)
SELECT book_id, title
FROM dim_books
WHERE to_tsvector('simple', coalesce(title,'') || ' ' || coalesce(authors,''))
      @@ plainto_tsquery('simple', 'stranger')
LIMIT 20;
