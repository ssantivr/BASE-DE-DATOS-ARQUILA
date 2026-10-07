CREATE TABLE IF NOT EXISTS spatial_elements (
    id SERIAL PRIMARY KEY,
    project_id INTEGER NOT NULL REFERENCES projects (id) ON DELETE CASCADE,
    room_id INTEGER REFERENCES rooms (id) ON DELETE SET NULL,
    layer VARCHAR(20) NOT NULL
        CHECK (layer IN ('structure', 'installations', 'finishes')),
    kind VARCHAR(40) NOT NULL,
    name VARCHAR(160) NOT NULL,
    work_status VARCHAR(20) NOT NULL DEFAULT 'existing'
        CHECK (work_status IN ('existing', 'planned', 'demolition')),
    min_x_m NUMERIC(8, 2) NOT NULL,
    min_y_m NUMERIC(8, 2) NOT NULL,
    min_z_m NUMERIC(8, 2) NOT NULL,
    max_x_m NUMERIC(8, 2) NOT NULL,
    max_y_m NUMERIC(8, 2) NOT NULL,
    max_z_m NUMERIC(8, 2) NOT NULL,
    mesh_ref VARCHAR(500),
    config JSONB NOT NULL DEFAULT '{}' CHECK (jsonb_typeof(config) = 'object'),
    source VARCHAR(20) NOT NULL DEFAULT 'manual',
    external_id VARCHAR(120),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CHECK (max_x_m > min_x_m),
    CHECK (max_y_m > min_y_m),
    CHECK (max_z_m > min_z_m)
);

CREATE INDEX IF NOT EXISTS idx_spatial_elements_project_layer
    ON spatial_elements (project_id, layer);

CREATE INDEX IF NOT EXISTS idx_spatial_elements_room_id
    ON spatial_elements (room_id) WHERE room_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_spatial_elements_footprint ON spatial_elements
    USING gist (box(point(min_x_m, min_y_m), point(max_x_m, max_y_m)));

CREATE UNIQUE INDEX IF NOT EXISTS uq_spatial_elements_external_id
    ON spatial_elements (project_id, source, external_id) WHERE external_id IS NOT NULL;
