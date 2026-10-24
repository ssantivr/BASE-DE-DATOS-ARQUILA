CREATE TABLE IF NOT EXISTS scene_settings (
    project_id INTEGER PRIMARY KEY REFERENCES projects (id) ON DELETE CASCADE,
    lighting JSONB NOT NULL DEFAULT '{}' CHECK (jsonb_typeof(lighting) = 'object'),
    camera_presets JSONB NOT NULL DEFAULT '[]' CHECK (jsonb_typeof(camera_presets) = 'array'),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- position and target are [x, y, z] in metres, like the cameras of walkthrough_steps.
CREATE TABLE IF NOT EXISTS walkthrough_points (
    id SERIAL PRIMARY KEY,
    project_id INTEGER NOT NULL REFERENCES projects (id) ON DELETE CASCADE,
    name VARCHAR(160) NOT NULL,
    position JSONB NOT NULL
        CHECK (jsonb_typeof(position) = 'array' AND jsonb_array_length(position) = 3),
    target JSONB NOT NULL
        CHECK (jsonb_typeof(target) = 'array' AND jsonb_array_length(target) = 3),
    sort_order INTEGER NOT NULL DEFAULT 0 CHECK (sort_order >= 0),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_walkthrough_points_project_order
    ON walkthrough_points (project_id, sort_order);

CREATE OR REPLACE TRIGGER trg_scene_settings_updated_at
    BEFORE UPDATE ON scene_settings FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE OR REPLACE TRIGGER trg_walkthrough_points_updated_at
    BEFORE UPDATE ON walkthrough_points FOR EACH ROW EXECUTE FUNCTION set_updated_at();
