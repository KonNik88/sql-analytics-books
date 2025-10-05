\set ON_ERROR_STOP on
\pset pager off
SET search_path TO dw, public;

\echo === TOP-5 BOOKS PER TAG ===
\i /analytics/topN_by_tag.sql

\echo
\echo === QUALITY SCORE (TOP 50) ===
\i /analytics/quality_score.sql

\echo
\echo === GROUPING SETS (LANGUAGE / YEAR) ===
\i /analytics/grouping_sets.sql

\echo
\echo === JSONB FILTER DEMO ===
\i /analytics/jsonb_filter.sql

-- ===== Optional heavy demos (disable by default) =====

-- \echo
-- \echo === COHORTS (SYNTHETIC TS) ===
-- \i /analytics/cohorts.sql

-- Для «пробелов активности» лучше ограничить время выполнения:
-- SET statement_timeout = '30s';
-- \echo
-- \echo === ACTIVITY GAPS (SYNTHETIC TS, capped 30s) ===
-- \i /analytics/window_gaps.sql
-- RESET statement_timeout;

\echo
\echo === FTS DEMO ===
\i /search/fts.sql

\echo
\echo === TRIGRAM FUZZY DEMO ===
\i /search/trigram_fuzzy.sql
