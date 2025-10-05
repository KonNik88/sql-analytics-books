SET search_path TO dw, public;

-- Create a read-only role and grant select on all dw tables
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'app_ro') THEN
    CREATE ROLE app_ro;
  END IF;
END$$;

GRANT USAGE ON SCHEMA dw TO app_ro;
GRANT SELECT ON ALL TABLES IN SCHEMA dw TO app_ro;

-- For future tables:
ALTER DEFAULT PRIVILEGES IN SCHEMA dw GRANT SELECT ON TABLES TO app_ro;

-- (Optional) create a login that uses this role (adjust password)
-- CREATE USER viewer WITH PASSWORD 'viewer';
-- GRANT app_ro TO viewer;
