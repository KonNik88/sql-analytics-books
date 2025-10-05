SET search_path TO dw, public;

-- Conditional aggregates: pivot-like counts for selected tags per book

WITH bt AS (
  SELECT bt.book_id, t.tag_name, bt.tag_count
  FROM bridge_book_tags bt
  JOIN dim_tags t USING(tag_id)
  WHERE t.tag_name IN ('fantasy','science-fiction','classic','philosophy')
)
SELECT
  b.book_id,
  b.title,
  SUM(CASE WHEN tag_name = 'fantasy'          THEN tag_count ELSE 0 END) AS tag_fantasy,
  SUM(CASE WHEN tag_name = 'science-fiction'  THEN tag_count ELSE 0 END) AS tag_scifi,
  SUM(CASE WHEN tag_name = 'classic'          THEN tag_count ELSE 0 END) AS tag_classic,
  SUM(CASE WHEN tag_name = 'philosophy'       THEN tag_count ELSE 0 END) AS tag_philosophy
FROM dim_books b
LEFT JOIN bt ON bt.book_id = b.book_id
GROUP BY b.book_id, b.title
ORDER BY b.book_id
LIMIT 200;
