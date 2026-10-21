CREATE TABLE IF NOT EXISTS project_versions (
    id SERIAL PRIMARY KEY,
    project_id INTEGER NOT NULL REFERENCES projects (id) ON DELETE CASCADE,
    version_number INTEGER NOT NULL CHECK (version_number > 0),
    label VARCHAR(160),
    snapshot JSONB NOT NULL DEFAULT '{}' CHECK (jsonb_typeof(snapshot) = 'object'),
    created_by INTEGER REFERENCES users (id) ON DELETE SET NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (project_id, version_number)
);

CREATE INDEX IF NOT EXISTS idx_project_versions_created_by
    ON project_versions (created_by) WHERE created_by IS NOT NULL;
