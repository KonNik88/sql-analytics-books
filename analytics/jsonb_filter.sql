SET search_path TO dw, public;

-- Примеры фильтров по JSONB: издатель или язык
SELECT book_id, title, meta->>'publisher' AS publisher
FROM dim_books
WHERE (meta->>'publisher') ILIKE '%Vintage%'
   OR language_code ILIKE 'en%';
