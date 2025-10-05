-- Indexes playbook: create/drop/index hints and sanity checks
-- Usage:
--   psql -h localhost -U app -d appdb -f tuning/indexes_playbook.sql

SET search_path TO dw, public;

\echo '== Current indexes (user tables) =='
SELECT schemaname, relname AS table, indexrelname AS index_name, idx_scan, idx_tup_read, idx_tup_fetch
FROM pg_stat_user_indexes
ORDER BY idx_scan DESC NULLS LAST, indexrelname;

\echo ''
\echo '== Create recommended indexes (idempotent) =='
-- Covering for fact_ratings by book/user
CREATE INDEX IF NOT EXISTS fact_ratings_by_book
  ON fact_ratings (book_id) INCLUDE (rating);
CREATE INDEX IF NOT EXISTS fact_ratings_by_user
  ON fact_ratings (user_id) INCLUDE (rating);

-- Bridge by tag (fan-out queries by tag)
CREATE INDEX IF NOT EXISTS bridge_book_tags_by_tag
  ON bridge_book_tags (tag_id) INCLUDE (book_id, tag_count);

-- JSONB GIN on books meta
CREATE INDEX IF NOT EXISTS dim_books_meta_gin
  ON dim_books USING GIN (meta);

-- FTS and trigram (extensions must exist; created in ddl/03_indexes.sql)
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE EXTENSION IF NOT EXISTS unaccent;
CREATE INDEX IF NOT EXISTS dim_books_fts_idx
  ON dim_books USING GIN (to_tsvector('simple', coalesce(title,'') || ' ' || coalesce(authors,'')));
CREATE INDEX IF NOT EXISTS dim_books_title_trgm
  ON dim_books USING GIN (title gin_trgm_ops);

\echo ''
\echo '== Analyze after index changes =='
VACUUM (ANALYZE) fact_ratings;
VACUUM (ANALYZE) bridge_book_tags;
VACUUM (ANALYZE) dim_books;

\echo ''
\echo '== Example partial index (optional): ratings for high-rated books only =='
-- Speeds specific queries that only touch books above a threshold
CREATE INDEX IF NOT EXISTS fact_ratings_high_books_partial
  ON fact_ratings (book_id)
  WHERE book_id IN (SELECT book_id FROM mv_top_books_quality WHERE quality_score >= 80);

\echo ''
\echo '== Show sizes =='
SELECT
  relname AS table,
  pg_size_pretty(pg_total_relation_size(relid)) AS total_size
FROM pg_catalog.pg_statio_user_tables
ORDER BY pg_total_relation_size(relid) DESC;

\echo ''
\echo '== Drop optional demo index (cleanup) =='
-- DROP INDEX IF EXISTS fact_ratings_high_books_partial;
