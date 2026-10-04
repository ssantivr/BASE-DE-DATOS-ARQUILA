CREATE TABLE IF NOT EXISTS rooms (
    id SERIAL PRIMARY KEY,
    project_id INTEGER NOT NULL REFERENCES projects (id) ON DELETE CASCADE,
    plan_id INTEGER NOT NULL REFERENCES plans (id) ON DELETE CASCADE,
    name VARCHAR(160) NOT NULL,
    x_m NUMERIC(8, 2) NOT NULL,
    y_m NUMERIC(8, 2) NOT NULL,
    width_m NUMERIC(6, 2) NOT NULL CHECK (width_m > 0),
    depth_m NUMERIC(6, 2) NOT NULL CHECK (depth_m > 0),
    height_m NUMERIC(6, 2) NOT NULL CHECK (height_m > 0),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_rooms_project_id ON rooms (project_id);
CREATE INDEX IF NOT EXISTS idx_rooms_plan_id ON rooms (plan_id);
