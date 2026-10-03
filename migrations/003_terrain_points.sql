CREATE TABLE IF NOT EXISTS terrain_points (
    id SERIAL PRIMARY KEY,
    terrain_id INTEGER NOT NULL REFERENCES terrains (id) ON DELETE CASCADE,
    position INTEGER NOT NULL CHECK (position >= 0),
    x_m NUMERIC(8, 2) NOT NULL,
    y_m NUMERIC(8, 2) NOT NULL,
    UNIQUE (terrain_id, position)
);

CREATE INDEX IF NOT EXISTS idx_terrain_points_terrain_id ON terrain_points (terrain_id);
