SET search_path TO dw, public;

-- Measure refresh timing for mv_top_books_quality

\timing on
REFRESH MATERIALIZED VIEW CONCURRENTLY mv_top_books_quality;
\timing off

-- Show top rows after refresh
SELECT * FROM mv_top_books_quality ORDER BY quality_score DESC LIMIT 10;
