SET search_path TO dw, public;

-- Дополнительные инварианты/ограничения
ALTER TABLE IF EXISTS dim_books
  ADD CONSTRAINT dim_books_avg_rating_range
  CHECK (avg_rating IS NULL OR (avg_rating >= 0 AND avg_rating <= 5));

-- Можно сделать внешние ключи DEFERRABLE (демо)
ALTER TABLE IF EXISTS bridge_book_tags
  ALTER CONSTRAINT bridge_book_tags_book_id_fkey DEFERRABLE INITIALLY IMMEDIATE,
  ALTER CONSTRAINT bridge_book_tags_tag_id_fkey  DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE IF EXISTS fact_ratings
  ALTER CONSTRAINT fact_ratings_user_id_fkey DEFERRABLE INITIALLY IMMEDIATE,
  ALTER CONSTRAINT fact_ratings_book_id_fkey DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE IF EXISTS fact_to_read
  ALTER CONSTRAINT fact_to_read_user_id_fkey DEFERRABLE INITIALLY IMMEDIATE,
  ALTER CONSTRAINT fact_to_read_book_id_fkey DEFERRABLE INITIALLY IMMEDIATE;
