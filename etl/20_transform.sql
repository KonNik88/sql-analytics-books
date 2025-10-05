SET search_path TO dw, public;

-- Витринное представление «событий по дням» (на основе оценок/списков)
CREATE OR REPLACE VIEW v_book_basic_stats AS
SELECT
  b.book_id, b.title,
  b.avg_rating, b.ratings_count,
  (meta->>'publisher') AS publisher,
  language_code, publication_year
FROM dim_books b;

-- Обновим матвью качества (если нужно)
-- REFRESH MATERIALIZED VIEW CONCURRENTLY mv_top_books_quality;
