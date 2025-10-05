SET search_path TO dw, public;

-- Fuzzy search on title using pg_trgm (GIN index on title).
-- Adjust the similarity threshold as needed (default ~0.3).

-- Set a stricter threshold for demo (optional)
SELECT set_limit(0.4);

-- Find titles similar to 'Stragner' (typo for 'Stranger')
SELECT book_id, title,
       similarity(title, 'Stragner') AS sim
FROM dim_books
WHERE title % 'Stragner'
ORDER BY sim DESC, book_id
LIMIT 20;

\echo ''

-- Another fuzzy example
SELECT book_id, title,
       similarity(title, 'Solariss') AS sim
FROM dim_books
WHERE title % 'Solariss'
ORDER BY sim DESC, book_id
LIMIT 20;
