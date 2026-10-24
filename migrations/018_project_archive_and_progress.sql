ALTER TABLE projects
    ADD COLUMN IF NOT EXISTS archived_at TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS cover_file_id INTEGER REFERENCES files (id) ON DELETE SET NULL,
    ADD COLUMN IF NOT EXISTS progress SMALLINT NOT NULL DEFAULT 0
        CHECK (progress BETWEEN 0 AND 100);

-- Projects already archived had no date: their last change is the best one known.
-- The trigger is paused so that this backfill does not move updated_at itself.
ALTER TABLE projects DISABLE TRIGGER trg_projects_updated_at;

UPDATE projects
SET archived_at = updated_at
WHERE status = 'archived'
  AND archived_at IS NULL;

ALTER TABLE projects ENABLE TRIGGER trg_projects_updated_at;

CREATE INDEX IF NOT EXISTS idx_projects_cover_file_id
    ON projects (cover_file_id) WHERE cover_file_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_projects_owner_active
    ON projects (owner_id, updated_at DESC) WHERE archived_at IS NULL;
