SET search_path TO dw, public;

-- Материализованная витрина «топ-книг» по интегральному скору
-- Скор = 0.6*квантиль рейтингов_count + 0.4*квантиль средней оценки
CREATE MATERIALIZED VIEW IF NOT EXISTS mv_top_books_quality AS
WITH q AS (
  SELECT
    book_id, ratings_count, avg_rating,
    NTILE(100) OVER (ORDER BY ratings_count NULLS LAST) AS rc_pct,
    NTILE(100) OVER (ORDER BY avg_rating   NULLS LAST) AS ar_pct
  FROM dim_books
)
SELECT
  book_id, ratings_count, avg_rating,
  (0.6*rc_pct + 0.4*ar_pct) AS quality_score
FROM q;

-- Уникальный индекс по book_id (для REFRESH CONCURRENTLY нужен уникальный индекс/строки)
CREATE UNIQUE INDEX IF NOT EXISTS mv_top_books_quality_uq
  ON mv_top_books_quality (book_id);
