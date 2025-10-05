\set ON_ERROR_STOP on
SET search_path TO dw, public;

-- Incremental load for ratings from seeds/ratings_delta.csv
-- File format: user_id,book_id,rating (header present).

DROP TABLE IF EXISTS _ratings_delta;
CREATE TABLE _ratings_delta(
  user_id INT,
  book_id INT,
  rating  INT
);

\copy _ratings_delta FROM 'seeds/ratings_delta.csv' CSV HEADER;

-- Ensure users exist
INSERT INTO dim_users(user_id)
SELECT DISTINCT user_id
FROM _ratings_delta
WHERE user_id IS NOT NULL
ON CONFLICT (user_id) DO NOTHING;

-- Upsert only rows that reference existing books to avoid FK errors
MERGE INTO fact_ratings AS tgt
USING (
  SELECT d.user_id, d.book_id, d.rating
  FROM _ratings_delta d
  JOIN dim_books b ON b.book_id = d.book_id
  WHERE d.rating BETWEEN 1 AND 5
) AS src
ON (tgt.user_id = src.user_id AND tgt.book_id = src.book_id)
WHEN MATCHED THEN
  UPDATE SET rating = src.rating
WHEN NOT MATCHED THEN
  INSERT (user_id, book_id, rating) VALUES (src.user_id, src.book_id, src.rating);

-- Cleanup (optional)
DROP TABLE IF EXISTS _ratings_delta;
