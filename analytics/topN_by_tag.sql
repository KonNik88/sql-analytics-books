SET search_path TO dw, public;

WITH by_tag AS (
  SELECT t.tag_name, bt.book_id, bt.tag_count
  FROM bridge_book_tags bt
  JOIN dim_tags t USING(tag_id)
),
ranked AS (
  SELECT tag_name, book_id, tag_count,
         DENSE_RANK() OVER (PARTITION BY tag_name ORDER BY tag_count DESC) AS rnk
  FROM by_tag
)
SELECT tag_name, book_id, tag_count
FROM ranked
WHERE rnk <= 5
ORDER BY tag_name, rnk;
