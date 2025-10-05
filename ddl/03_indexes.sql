SET search_path TO dw, public;

-- Покрывающие индексы под частые доступы
CREATE INDEX IF NOT EXISTS fact_ratings_by_book
  ON fact_ratings (book_id) INCLUDE (rating);

CREATE INDEX IF NOT EXISTS fact_ratings_by_user
  ON fact_ratings (user_id) INCLUDE (rating);

CREATE INDEX IF NOT EXISTS bridge_book_tags_by_tag
  ON bridge_book_tags (tag_id) INCLUDE (book_id, tag_count);

-- JSONB по книгам (для фильтров по meta)
CREATE INDEX IF NOT EXISTS dim_books_meta_gin
  ON dim_books USING GIN (meta);

-- Full-Text Search и триграммы (опционально; требуют EXTENSION)
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE EXTENSION IF NOT EXISTS unaccent;

-- FTS индекс по title + authors
CREATE INDEX IF NOT EXISTS dim_books_fts_idx
  ON dim_books USING GIN (to_tsvector('simple', coalesce(title,'') || ' ' || coalesce(authors,'')));

-- Trigram для «похожих» названий
CREATE INDEX IF NOT EXISTS dim_books_title_trgm
  ON dim_books USING GIN (title gin_trgm_ops);
