-- Undoes 016_project_coordinates.sql. The saved coordinates are lost: back up first.
-- psql "$URL" --set ON_ERROR_STOP=1 --single-transaction --file rollback/016_down.sql
SET LOCAL lock_timeout = '5s';

ALTER TABLE projects
    DROP COLUMN IF EXISTS location_zoom,
    DROP COLUMN IF EXISTS longitude,
    DROP COLUMN IF EXISTS latitude;

DELETE FROM schema_migrations WHERE version = '016_project_coordinates.sql';
