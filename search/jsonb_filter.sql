SET search_path TO dw, public;

-- JSONB search examples on dim_books.meta

-- Find by publisher substring (case-insensitive)
SELECT book_id, title, meta->>'publisher' AS publisher
FROM dim_books
WHERE (meta->>'publisher') ILIKE '%Penguin%'
ORDER BY book_id
LIMIT 50;

\echo ''

-- Find rows where isbn13 exists
SELECT book_id, title, meta->>'isbn13' AS isbn13
FROM dim_books
WHERE meta ? 'isbn13'
ORDER BY book_id
LIMIT 50;
