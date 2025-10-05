# SQL Analytics (Books) — PostgreSQL

Reproducible **SQL portfolio project** on PostgreSQL (books domain).  
Built from Goodbooks-like CSV seeds and focused on **advanced SQL** and **engineering good practices**.

**What this repo demonstrates**
- **Data modeling:** star schema with a bridge table (`book ↔ tag`)
- **Advanced SQL:** window functions, JSONB, GROUPING SETS, recursive CTE
- **Search:** full-text search (FTS) + `pg_trgm` fuzzy matches
- **Engineering:** covering/partial/GIN indexes, materialized views, incremental MERGE loads
- **Quality:** pgTAP tests, CI-friendly layout (GitHub Actions)
- **Reproducible:** Docker quickstart and alternative run on a remote VM via SSH tunnel

> Seeds are small (LFS-free) so CI remains fast.  
> **Note:** the showcase runner `analytics/readme_index.sql` uses **absolute paths** (`/analytics/...`, `/search/...`) for reliable execution **inside the container** and in **CI**. When running from your host, you can call the individual files from `analytics/` as usual.

---

## Table of Contents
- [Schema](#schema)
- [Seeds (CSV inputs)](#seeds-csv-inputs)
- [Project Layout](#project-layout)
- [Quickstart — Docker](#quickstart—docker)
- [Run against Remote VM (SSH tunnel)](#run-against-remote-vm-ssh-tunnel)
- [Initialization Scripts](#initialization-scripts)
- [Analytics Queries (how to run)](#analytics-queries-how-to-run)
- [Search: FTS & Trigram](#search-fts--trigram)
- [Incremental Loads (MERGE)](#incremental-loads-merge)
- [Testing (pgTAP)](#testing-pgtap)
- [Performance & Tuning](#performance--tuning)
- [CI (GitHub Actions)](#ci-github-actions)
- [Design Decisions](#design-decisions)
- [License](#license)

---

## Schema

Star-like data mart in schema `dw`:

```
dw.dim_books(book_id PK, title, authors, language_code, publication_year,
             avg_rating, ratings_count, meta JSONB)

dw.dim_users(user_id PK)

dw.dim_tags(tag_id PK, tag_name)

dw.bridge_book_tags(book_id FK → dim_books, tag_id FK → dim_tags,
                    tag_count, PK(book_id, tag_id))

dw.fact_ratings(user_id FK → dim_users, book_id FK → dim_books,
                rating CHECK 1..5, PK(user_id, book_id))

dw.fact_to_read(user_id FK → dim_users, book_id FK → dim_books,
                PK(user_id, book_id))
```

Key extras:
- `meta JSONB` in `dim_books` (e.g., `isbn`, `isbn13`, `publisher`) + **GIN** index
- covering & partial indexes for frequent filters/joins
- materialized views for “top books” / composite quality scores

---

## Seeds (CSV inputs)

Place CSV files in `seeds/` (UTF-8, with header). Typical columns:

- `books.csv`  
  `book_id,title,authors,language_code,original_publication_year,average_rating,ratings_count,isbn,isbn13,publisher`
- `ratings.csv`  
  `user_id,book_id,rating`
- `tags.csv`  
  `tag_id,tag_name`
- `book_tags.csv`  
  **Either** `book_id,tag_id,count` **or** `goodreads_book_id,tag_id,count`
- `to_read.csv`  
  `user_id,book_id`

> If your `book_tags.csv` uses `goodreads_book_id`, the ETL will normalize it to `book_id`.

Keep seeds small (a few MB total) so CI remains snappy.

---

## Project Layout

```
sql-analytics-books/
├─ docker-compose.yml
├─ README.md
├─ LICENSE
├─ .gitignore
├─ seeds/                    # CSV seeds (books, ratings, tags, book_tags, to_read)
├─ ddl/                      # schema & objects
│  ├─ 00_schema.sql
│  ├─ 01_tables.sql
│  ├─ 02_constraints.sql
│  ├─ 03_indexes.sql
│  └─ 04_matviews.sql
├─ etl/
│  ├─ 10_copy_seeds.sql      # initial load (COPY/INSERT)
│  └─ 20_transform.sql       # derived views/denorm steps
├─ dml/
│  ├─ merge_ratings.sql      # MERGE from ratings_delta.csv (incremental)
│  └─ merge_book_tags.sql
├─ analytics/                # showcase SQL
│  ├─ topN_by_tag.sql        # window funcs + DENSE_RANK
│  ├─ quality_score.sql      # NTILE over avg_rating/ratings_count
│  ├─ grouping_sets.sql      # GROUPING SETS / ROLLUP / CUBE
│  ├─ window_percentiles.sql # PERCENTILE_CONT
│  ├─ pivot_tags.sql         # conditional aggs (FILTER)
│  ├─ also_read_graph.sql    # WITH RECURSIVE
│  └─ readme_index.sql       # runs the showcase in one shot
├─ search/
│  ├─ jsonb_filter.sql       # JSONB queries
│  ├─ fts.sql                # full-text search
│  └─ trigram_fuzzy.sql      # pg_trgm similarities
├─ tuning/
│  ├─ explain_before_after.sql
│  ├─ refresh_matview.sql
│  └─ indexes_playbook.sql
├─ security/
│  └─ roles.sql              # read-only role / (optional) RLS demo
├─ tests/
│  ├─ pgtap_setup.sql
│  ├─ test_basic.sql
│  └─ test_queries.sql
└─ init/
   ├─ docker_init.sql        # auto-run inside container
   └─ local_init.sql         # manual psql runner
```

---

## Quickstart — Docker

Requires Docker Desktop (or any recent Docker).

```bash
# 1) Start Postgres 16 with mounted init & seeds
docker compose up -d

# 2) Sanity check: count rows
psql -h localhost -U app -d appdb -c "SELECT COUNT(*) FROM dw.dim_books;"

# 3) Run individual showcase queries (host → relative paths)
psql -h localhost -U app -d appdb -f analytics/topN_by_tag.sql
psql -h localhost -U app -d appdb -f analytics/quality_score.sql
psql -h localhost -U app -d appdb -f analytics/grouping_sets.sql

# 4) Or run the aggregator (inside container → absolute paths)
docker exec -it sql_project-db-1 bash -lc "psql -U app -d appdb -f /analytics/readme_index.sql > /analytics/run.log 2>&1"
docker cp sql_project-db-1:/analytics/run.log ./run.log
```

Default credentials are set in `docker-compose.yml`:
```
POSTGRES_USER=app
POSTGRES_PASSWORD=app
POSTGRES_DB=appdb
```

---

## Run against Remote VM (SSH tunnel)

If you have Postgres on a remote Ubuntu VM:

```bash
# open tunnel (Windows PowerShell / Linux / macOS)
ssh -L 5432:localhost:5432 user@VM_IP

# run init and queries against the tunneled localhost:5432
psql -h localhost -U app -d appdb -f init/local_init.sql
psql -h localhost -U app -d appdb -f analytics/readme_index.sql
```

---

## Initialization Scripts

- `init/docker_init.sql` — executed automatically by the container entrypoint:
  - creates schema & tables,
  - loads seeds,
  - builds indexes & materialized views,
  - prepares derived views.

- `init/local_init.sql` — same sequence, but with relative paths (for local/VM).

---

## Analytics Queries (how to run)

Run each file individually (host paths):

```bash
psql -h localhost -U app -d appdb -f analytics/topN_by_tag.sql
psql -h localhost -U app -d appdb -f analytics/quality_score.sql
psql -h localhost -U app -d appdb -f analytics/grouping_sets.sql
```

Or run the aggregator **inside the container** (absolute paths):

```bash
docker exec -it sql_project-db-1 bash -lc "psql -U app -d appdb -f /analytics/readme_index.sql > /analytics/run.log 2>&1"
docker cp sql_project-db-1:/analytics/run.log ./run.log
```

The queries demonstrate:
- rank-based **Top-N per tag** (window functions, `DENSE_RANK`)
- `NTILE` quality score combining `avg_rating` and `ratings_count`
- **GROUPING SETS** to get multiple rollups in one pass
- **percentiles** with `PERCENTILE_CONT`
- a small **recursive CTE** graph (“also read via shared raters”)

---

## Search: FTS & Trigram

Full-Text Search (tsvector/tsquery) and trigram fuzzy matching (`pg_trgm`).

**From the container (absolute paths):**
```bash
docker exec -it sql_project-db-1 psql -U app -d appdb -f /search/fts.sql
docker exec -it sql_project-db-1 psql -U app -d appdb -f /search/trigram_fuzzy.sql
```

**From the host (relative paths):**
```bash
psql -h localhost -U app -d appdb -f search/fts.sql
psql -h localhost -U app -d appdb -f search/trigram_fuzzy.sql
```

Make sure the related indexes are defined in `ddl/03_indexes.sql`.

---

## Incremental Loads (MERGE)

- Put deltas (e.g., `ratings_delta.csv`) into `seeds/` and run:
  ```bash
  psql -h localhost -U app -d appdb -f dml/merge_ratings.sql
  ```
- Uses `MERGE` (PostgreSQL 15+) to upsert into `dw.fact_ratings`.
- Similar script provided for `bridge_book_tags`.

---

## Testing (pgTAP)

We use a custom image (`postgres:16` + **pgTAP**) so tests run identically locally and in CI.

```bash
# enable extension & setup (idempotent)
docker exec -it sql_project-db-1 psql -U app -d appdb -f /tests/pgtap_setup.sql

# schema/load sanity
docker exec -it sql_project-db-1 psql -U app -d appdb -f /tests/test_basic.sql

# behavioral tests (showcase/search/indexes)
docker exec -it sql_project-db-1 psql -U app -d appdb -f /tests/test_queries.sql
```

Expect `ok ...` lines from pgTAP and a clean `finish()`.

---

## Performance & Tuning

- `tuning/explain_before_after.sql` shows **EXPLAIN (ANALYZE, BUFFERS)** before/after creating indexes.
- `ddl/04_matviews.sql` defines materialized views with a unique index → supports `REFRESH CONCURRENTLY`.
- `tuning/refresh_matview.sql` illustrates refresh timings and the impact of indexes.
- (Optional) `ddl/01_tables.sql` can switch `fact_ratings` to **partitioned** by hash(`user_id`) for larger datasets.

---

## CI (GitHub Actions)

> Badge will be added after the first green run.

Template (replace `USER/REPO`):

```markdown
[![CI](https://github.com/USER/REPO/actions/workflows/ci.yml/badge.svg)](https://github.com/USER/REPO/actions/workflows/ci.yml)
```

CI spins up the container, runs init, executes pgTAP tests and the showcase (`readme_index.sql`), and uploads `run.log` as an artifact.

---

## Design Decisions

- **Star schema** for clarity: simple dimensions + one bridge for `book ↔ tag`.
- **JSONB** in `dim_books.meta` for flexible attributes (`isbn`, `publisher`, etc.) with GIN index.
- **Covering/partial indexes** targeting frequent access patterns (e.g., `fact_ratings` by `book_id`).
- **Materialized views** for “Top books” to showcase serving-layer patterns in SQL.
- **Incremental MERGE** scripts to mimic real-world upserts.
- **CI-friendly**: small seeds (no LFS), deterministic init, `ON_ERROR_STOP` in psql scripts.

---

## License

This project is released under the **MIT License**. See [`LICENSE`](./LICENSE).

---

**Tips**
- Ensure CSVs are **UTF-8** and include **headers**.
- If your seeds are large, sample them to keep CI lean.
- For local development with DBeaver, connect to `localhost:5432` (Docker) or use an SSH tunnel to your VM.

Happy querying!
