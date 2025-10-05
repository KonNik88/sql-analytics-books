SET search_path TO dw, public;

-- "Also read" graph via shared raters (2-hop neighborhood)
-- Input: pick a seed book_id; change :seed as needed.
\set seed 1

WITH
seed AS (
  SELECT :seed::int AS book_id
),
-- users who rated the seed book
seed_users AS (
  SELECT DISTINCT r.user_id
  FROM fact_ratings r
  JOIN seed s ON s.book_id = r.book_id
),
-- other books these users rated
neighbors AS (
  SELECT r.book_id, COUNT(DISTINCT r.user_id) AS shared_users
  FROM fact_ratings r
  JOIN seed_users u ON u.user_id = r.user_id
  WHERE r.book_id <> (SELECT book_id FROM seed)
  GROUP BY r.book_id
),
-- rank neighbors by shared user count
ranked AS (
  SELECT book_id, shared_users,
         DENSE_RANK() OVER (ORDER BY shared_users DESC) AS rnk
  FROM neighbors
)
SELECT b.book_id, b.title, r.shared_users
FROM ranked r
JOIN dim_books b USING(book_id)
WHERE rnk <= 20
ORDER BY r.shared_users DESC, b.book_id;
