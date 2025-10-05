SET search_path TO dw, public;

-- Percentiles and median over avg_rating and ratings_count using PERCENTILE_CONT

SELECT
  PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY avg_rating)      AS median_avg_rating,
  PERCENTILE_CONT(0.9) WITHIN GROUP (ORDER BY avg_rating)      AS p90_avg_rating,
  PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY ratings_count)   AS median_ratings_count,
  PERCENTILE_CONT(0.9) WITHIN GROUP (ORDER BY ratings_count)   AS p90_ratings_count
FROM dim_books;
