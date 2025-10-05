SET search_path TO dw, public;

SELECT *
FROM mv_top_books_quality
ORDER BY quality_score DESC
LIMIT 50;
