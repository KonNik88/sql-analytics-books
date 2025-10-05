\set ON_ERROR_STOP on
\cd /docker-entrypoint-initdb.d 

\i /docker-entrypoint-initdb.d/ddl/00_schema.sql
\i /docker-entrypoint-initdb.d/ddl/01_tables.sql
\i /docker-entrypoint-initdb.d/ddl/02_constraints.sql
\i /docker-entrypoint-initdb.d/ddl/03_indexes.sql
\i /docker-entrypoint-initdb.d/etl/10_copy_seeds.sql
\i /docker-entrypoint-initdb.d/etl/20_transform.sql
\i /docker-entrypoint-initdb.d/ddl/04_matviews.sql
