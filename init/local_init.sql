\set ON_ERROR_STOP on
\cd .         

\i ddl/00_schema.sql
\i ddl/01_tables.sql
\i ddl/02_constraints.sql
\i ddl/03_indexes.sql
\i etl/10_copy_seeds.sql
\i etl/20_transform.sql
\i ddl/04_matviews.sql
