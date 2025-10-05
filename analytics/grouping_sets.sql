SET search_path TO dw, public;

SELECT
  COALESCE(language_code, 'ALL') AS lang,
  publication_year,
  COUNT(*) AS n_books
FROM dim_books
GROUP BY GROUPING SETS (
  (language_code, publication_year),
  (language_code),
  ()
)
ORDER BY lang, publication_year NULLS LAST;
