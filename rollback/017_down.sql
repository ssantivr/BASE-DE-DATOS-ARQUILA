-- Undoes 017_ai_extractions.sql. The extraction history is lost: back up first.
-- psql "$URL" --set ON_ERROR_STOP=1 --single-transaction --file rollback/017_down.sql
SET LOCAL lock_timeout = '5s';

DROP TABLE IF EXISTS ai_extractions;

DELETE FROM schema_migrations WHERE version = '017_ai_extractions.sql';
