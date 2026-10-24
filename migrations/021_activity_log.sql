CREATE TABLE IF NOT EXISTS activity_log (
    id BIGSERIAL PRIMARY KEY,
    project_id INTEGER REFERENCES projects (id) ON DELETE CASCADE,
    user_id INTEGER REFERENCES users (id) ON DELETE SET NULL,
    action VARCHAR(40) NOT NULL,
    entity_type VARCHAR(40),
    entity_id INTEGER,
    detail JSONB NOT NULL DEFAULT '{}' CHECK (jsonb_typeof(detail) = 'object'),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CHECK (entity_id IS NULL OR entity_type IS NOT NULL)
);

CREATE INDEX IF NOT EXISTS idx_activity_log_project_created
    ON activity_log (project_id, created_at DESC) WHERE project_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_activity_log_user_created
    ON activity_log (user_id, created_at DESC) WHERE user_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_activity_log_entity
    ON activity_log (entity_type, entity_id) WHERE entity_id IS NOT NULL;
