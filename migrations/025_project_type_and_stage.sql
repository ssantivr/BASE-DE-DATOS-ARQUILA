-- project_type: optional, with the vocabulary of properties.property_type.
-- stage: explicit life cycle of a project. status keeps its values (draft, active,
-- archived) for the clients that already use them.
ALTER TABLE projects
    ADD COLUMN IF NOT EXISTS project_type VARCHAR(20)
        CHECK (project_type IN ('house', 'apartment_building', 'commercial', 'mixed_use')),
    ADD COLUMN IF NOT EXISTS stage VARCHAR(20) NOT NULL DEFAULT 'draft'
        CHECK (stage IN ('draft', 'in_progress', 'completed', 'archived'));

-- Existing projects take the stage that their status, archive date and progress
-- describe. The trigger is off so that updated_at keeps the date of the last real change.
ALTER TABLE projects DISABLE TRIGGER trg_projects_updated_at;

UPDATE projects
SET stage = CASE
    WHEN status = 'archived' OR archived_at IS NOT NULL THEN 'archived'
    WHEN progress = 100 THEN 'completed'
    WHEN status = 'active' THEN 'in_progress'
    ELSE 'draft'
END;

ALTER TABLE projects ENABLE TRIGGER trg_projects_updated_at;

CREATE INDEX IF NOT EXISTS idx_projects_owner_stage ON projects (owner_id, stage);

CREATE INDEX IF NOT EXISTS idx_projects_owner_type
    ON projects (owner_id, project_type) WHERE project_type IS NOT NULL;
