-- Audit trail of the change history (R18, D-TZ).
--
-- 1. activity_log.created_at becomes timestamptz. The old column was filled by
--    CURRENT_TIMESTAMP in the session time zone, so each value is read in the server's
--    current TimeZone setting (UTC on a UTC server, America/Bogota on the local one) and
--    stored as an absolute instant. The ALTER only runs while the column is still
--    "timestamp without time zone": running it twice would shift every row.
-- 2. New columns, all optional so that rows written before this migration stay as they are
--    (no backfill: nothing is known about their origin or their values):
--      origin         who made the change: 'user', 'ai' or 'system'
--      source_module  the screen or module that made it ('viewer', 'terrain', ...)
--      old_value      the changed fields before the change (JSON object)
--      new_value      the same fields after the change (JSON object)
--
-- Lock: ALTER COLUMN TYPE takes ACCESS EXCLUSIVE on activity_log and rewrites the table
-- and its three indexes. ADD COLUMN without a default only touches the catalog.

DO $$
BEGIN
    IF (
        SELECT data_type
        FROM information_schema.columns
        WHERE table_schema = current_schema()
          AND table_name = 'activity_log'
          AND column_name = 'created_at'
    ) = 'timestamp without time zone' THEN
        ALTER TABLE activity_log
            ALTER COLUMN created_at TYPE TIMESTAMPTZ
                USING created_at AT TIME ZONE current_setting('TimeZone'),
            ALTER COLUMN created_at SET DEFAULT CURRENT_TIMESTAMP;
    END IF;
END $$;

ALTER TABLE activity_log
    ADD COLUMN IF NOT EXISTS origin VARCHAR(10),
    ADD COLUMN IF NOT EXISTS source_module VARCHAR(40),
    ADD COLUMN IF NOT EXISTS old_value JSONB,
    ADD COLUMN IF NOT EXISTS new_value JSONB;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'activity_log_origin_check' AND conrelid = 'activity_log'::regclass
    ) THEN
        ALTER TABLE activity_log
            ADD CONSTRAINT activity_log_origin_check
                CHECK (origin IS NULL OR origin IN ('user', 'ai', 'system'));
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'activity_log_old_value_check' AND conrelid = 'activity_log'::regclass
    ) THEN
        ALTER TABLE activity_log
            ADD CONSTRAINT activity_log_old_value_check
                CHECK (old_value IS NULL OR jsonb_typeof(old_value) = 'object');
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'activity_log_new_value_check' AND conrelid = 'activity_log'::regclass
    ) THEN
        ALTER TABLE activity_log
            ADD CONSTRAINT activity_log_new_value_check
                CHECK (new_value IS NULL OR jsonb_typeof(new_value) = 'object');
    END IF;
END $$;
