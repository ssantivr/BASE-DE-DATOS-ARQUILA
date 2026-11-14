-- Reverts migrations/028_activity_log_audit.sql. Run by hand, never by the migration runner.
-- It drops the four audit columns (their values are lost) and turns created_at back into a
-- timestamp in the server's current TimeZone, which is what the column held before 028.
-- The type change only runs while the column is timestamptz, so a second run does nothing.

BEGIN;

ALTER TABLE activity_log
    DROP CONSTRAINT IF EXISTS activity_log_origin_check,
    DROP CONSTRAINT IF EXISTS activity_log_old_value_check,
    DROP CONSTRAINT IF EXISTS activity_log_new_value_check,
    DROP COLUMN IF EXISTS origin,
    DROP COLUMN IF EXISTS source_module,
    DROP COLUMN IF EXISTS old_value,
    DROP COLUMN IF EXISTS new_value;

DO $$
BEGIN
    IF (
        SELECT data_type
        FROM information_schema.columns
        WHERE table_schema = current_schema()
          AND table_name = 'activity_log'
          AND column_name = 'created_at'
    ) = 'timestamp with time zone' THEN
        ALTER TABLE activity_log
            ALTER COLUMN created_at TYPE TIMESTAMP
                USING created_at AT TIME ZONE current_setting('TimeZone'),
            ALTER COLUMN created_at SET DEFAULT CURRENT_TIMESTAMP;
    END IF;
END $$;

DELETE FROM schema_migrations WHERE version = '028_activity_log_audit.sql';

COMMIT;
