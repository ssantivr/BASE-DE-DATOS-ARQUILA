CREATE TABLE IF NOT EXISTS walkthrough_steps (
    id SERIAL PRIMARY KEY,
    project_id INTEGER NOT NULL REFERENCES projects (id) ON DELETE CASCADE,
    room_id INTEGER REFERENCES rooms (id) ON DELETE SET NULL,
    position INTEGER NOT NULL CHECK (position >= 0),
    title VARCHAR(160) NOT NULL,
    description TEXT,
    duration_ms INTEGER NOT NULL DEFAULT 5000 CHECK (duration_ms BETWEEN 1000 AND 60000),
    view_config JSONB NOT NULL DEFAULT '{}' CHECK (jsonb_typeof(view_config) = 'object'),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS renovation_logs (
    id SERIAL PRIMARY KEY,
    project_id INTEGER NOT NULL REFERENCES projects (id) ON DELETE CASCADE,
    room_id INTEGER REFERENCES rooms (id) ON DELETE SET NULL,
    spatial_element_id INTEGER REFERENCES spatial_elements (id) ON DELETE SET NULL,
    created_by INTEGER REFERENCES users (id) ON DELETE SET NULL,
    layer VARCHAR(20) NOT NULL
        CHECK (layer IN ('structure', 'installations', 'finishes')),
    title VARCHAR(160) NOT NULL,
    description TEXT,
    status VARCHAR(20) NOT NULL DEFAULT 'planned'
        CHECK (status IN ('planned', 'in_progress', 'completed', 'cancelled')),
    planned_start DATE,
    planned_end DATE,
    completed_at TIMESTAMP,
    estimated_cost NUMERIC(12, 2) CHECK (estimated_cost >= 0),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CHECK (planned_end >= planned_start)
);

CREATE INDEX IF NOT EXISTS idx_walkthrough_steps_project_position
    ON walkthrough_steps (project_id, position);

CREATE INDEX IF NOT EXISTS idx_walkthrough_steps_room_id
    ON walkthrough_steps (room_id) WHERE room_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_renovation_logs_project_status
    ON renovation_logs (project_id, status);

CREATE INDEX IF NOT EXISTS idx_renovation_logs_room_id
    ON renovation_logs (room_id) WHERE room_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_renovation_logs_spatial_element_id
    ON renovation_logs (spatial_element_id) WHERE spatial_element_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_renovation_logs_created_by
    ON renovation_logs (created_by) WHERE created_by IS NOT NULL;
