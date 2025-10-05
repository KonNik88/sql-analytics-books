-- Cohorts by "first rating month" using synthetic timestamps
-- We deterministically assign each user's rating events to days starting from 2023-01-01
-- so that cohorts/retention can be demonstrated without real timestamps.

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
    book_id,
    (TIMESTAMP '2023-01-01' + (rn - 1) * INTERVAL '1 day') AS synthetic_ts
  FROM rated
),
first_seen AS (
  SELECT
    user_id,
    date_trunc('month', MIN(synthetic_ts)) AS cohort_month
  FROM events
  GROUP BY user_id
),
activity AS (
  SELECT
    user_id,
    date_trunc('month', synthetic_ts) AS activity_month
  FROM events
  GROUP BY user_id, date_trunc('month', synthetic_ts)
),
cohorts AS (
  SELECT
    fs.cohort_month,
    a.activity_month,
    COUNT(DISTINCT a.user_id) AS active_users
  FROM first_seen fs
  JOIN activity a USING (user_id)
  GROUP BY fs.cohort_month, a.activity_month
),
final AS (
  SELECT
    cohort_month,
    activity_month,
    EXTRACT(YEAR FROM cohort_month)::int AS cohort_year,
    EXTRACT(MONTH FROM cohort_month)::int AS cohort_m,
    EXTRACT(YEAR FROM activity_month)::int AS act_year,
    EXTRACT(MONTH FROM activity_month)::int AS act_m,
    ( (EXTRACT(YEAR FROM activity_month) - EXTRACT(YEAR FROM cohort_month)) * 12
      + (EXTRACT(MONTH FROM activity_month) - EXTRACT(MONTH FROM cohort_month)) )::int AS cohort_age_m,
    active_users
  FROM cohorts
)
SELECT *
FROM final
ORDER BY cohort_month, activity_month;
