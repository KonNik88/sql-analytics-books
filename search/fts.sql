SET search_path TO dw, public;

-- Full-Text Search over title + authors.
-- Requires indexes from ddl/03_indexes.sql (GIN on to_tsvector).
-- Example: search for 'stranger' and 'solaris'.

-- Basic FTS query
SELECT book_id, title, authors
FROM dim_books
WHERE to_tsvector('simple', coalesce(title,'') || ' ' || coalesce(authors,''))
      @@ plainto_tsquery('simple', 'stranger')
ORDER BY book_id
LIMIT 20;

\echo ''

-- Phrase with multiple terms
SELECT book_id, title, authors
FROM dim_books
WHERE to_tsvector('simple', coalesce(title,'') || ' ' || coalesce(authors,''))
      @@ plainto_tsquery('simple', 'solaris')
ORDER BY book_id
LIMIT 20;
