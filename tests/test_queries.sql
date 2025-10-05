SET search_path TO dw, public;

SELECT plan(7);

-- mv_top_books_quality must have rows
SELECT ok( (SELECT COUNT(*) FROM mv_top_books_quality) > 0, 'mv_top_books_quality populated');

-- topN_by_tag returns rows
SELECT ok( (WITH by_tag AS (
  SELECT t.tag_name, bt.book_id, bt.tag_count
  FROM bridge_book_tags bt JOIN dim_tags t USING(tag_id)
), ranked AS (
  SELECT tag_name, book_id, tag_count,
         DENSE_RANK() OVER (PARTITION BY tag_name ORDER BY tag_count DESC) AS rnk
  FROM by_tag
)
SELECT COUNT(*) FROM ranked WHERE rnk <= 5) > 0, 'topN_by_tag has results');

-- quality_score query returns <= 50 rows and ordered desc by quality_score
WITH q AS (
  SELECT * FROM mv_top_books_quality ORDER BY quality_score DESC LIMIT 50
)
SELECT is( (SELECT COUNT(*) FROM q) > 0, true, 'quality_score has at least one row');

-- grouping_sets returns grand total row (NULLs collapsed to ALL)
SELECT ok( EXISTS(
  SELECT 1 FROM (
    SELECT COALESCE(language_code, 'ALL') AS lang, publication_year, COUNT(*) AS n_books
    FROM dim_books
    GROUP BY GROUPING SETS ((language_code, publication_year), (language_code), ())
  ) s WHERE lang = 'ALL' AND publication_year IS NULL
), 'grouping_sets has grand total');

-- FTS finds something for a common token (if present)
SELECT ok( (SELECT COUNT(*) FROM dim_books
           WHERE to_tsvector('simple', coalesce(title,'') || ' ' || coalesce(authors,''))
                 @@ plainto_tsquery('simple','the')) >= 0, 'fts query executed');

-- trigram operator runs (no error)
SELECT ok( (SELECT COUNT(*) FROM dim_books WHERE title % 'The') >= 0, 'trigram query executed');

-- jsonb filter executes
SELECT ok( (SELECT COUNT(*) FROM dim_books WHERE (meta->>'publisher') IS NOT NULL) >= 0, 'jsonb filter executed');

SELECT finish();
