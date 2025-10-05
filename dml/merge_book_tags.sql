\set ON_ERROR_STOP on
SET search_path TO dw, public;

-- Incremental load for book_tags from seeds/book_tags_delta.csv
-- Format: goodreads_book_id,tag_id,tag_count

DROP TABLE IF EXISTS _book_tags_delta;
CREATE TABLE _book_tags_delta(
  goodreads_book_id INT,
  tag_id            INT,
  tag_count         INT
);

\copy _book_tags_delta FROM 'seeds/book_tags_delta.csv' CSV HEADER;

WITH map AS (
  SELECT
    book_id,
    NULLIF(meta->>'goodreads_book_id','')::int AS goodreads_book_id
  FROM dim_books
)
MERGE INTO bridge_book_tags AS tgt
USING (
  SELECT m.book_id, d.tag_id, d.tag_count
  FROM _book_tags_delta d
  JOIN map m ON m.goodreads_book_id = d.goodreads_book_id
) AS src
ON (tgt.book_id = src.book_id AND tgt.tag_id = src.tag_id)
WHEN MATCHED THEN
  UPDATE SET tag_count = src.tag_count
WHEN NOT MATCHED THEN
  INSERT (book_id, tag_id, tag_count) VALUES (src.book_id, src.tag_id, src.tag_count);

DROP TABLE IF EXISTS _book_tags_delta;
