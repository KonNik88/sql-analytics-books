-- Gap detection per user (days with no events) using synthetic timestamps
-- Events are placed on deterministic daily grid per user (ROW_NUMBER order).

SET search_path TO dw, public;

WITH rated AS (
  SELECT
    fr.user_id,
    fr.book_id,
    ROW_NUMBER() OVER (PARTITION BY fr.user_id ORDER BY fr.book_id) AS rn
  FROM fact_ratings fr
),
events AS (
  SELECT
    user_id,
    (TIMESTAMP '2023-01-01' + (rn - 1) * INTERVAL '1 day')::date AS d
  FROM rated
),
range_per_user AS (
  SELECT
    user_id,
    MIN(d) AS d_min,
    MAX(d) AS d_max
  FROM events
  GROUP BY user_id
),
calendar AS (
  SELECT
    rpu.user_id,
    gs::date AS d
  FROM range_per_user rpu
  CROSS JOIN LATERAL generate_series(rpu.d_min, rpu.d_max, INTERVAL '1 day') AS gs
),
flags AS (
  SELECT
    c.user_id,
    c.d,
    EXISTS (SELECT 1 FROM events e WHERE e.user_id = c.user_id AND e.d = c.d) AS has_event
  FROM calendar c
),
grouped AS (
  SELECT
    user_id,
    d,
    has_event,
    CASE
      WHEN has_event THEN NULL
      ELSE d - (ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY d)) * INTERVAL '1 day'
    END AS grp
  FROM flags
)
SELECT
  user_id,
  MIN(d) AS gap_start,
  MAX(d) AS gap_end,
  COUNT(*) AS days
FROM grouped
WHERE has_event = false
GROUP BY user_id, grp
HAVING COUNT(*) > 0
ORDER BY user_id, gap_start;
