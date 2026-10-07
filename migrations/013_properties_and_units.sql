CREATE TABLE IF NOT EXISTS properties (
    id SERIAL PRIMARY KEY,
    project_id INTEGER NOT NULL REFERENCES projects (id) ON DELETE CASCADE,
    name VARCHAR(160) NOT NULL,
    property_type VARCHAR(20) NOT NULL DEFAULT 'house'
        CHECK (property_type IN ('house', 'apartment_building', 'commercial', 'mixed_use')),
    address VARCHAR(255),
    status VARCHAR(20) NOT NULL DEFAULT 'planning'
        CHECK (status IN ('planning', 'under_construction', 'renovation', 'delivered')),
    spatial_metadata JSONB NOT NULL DEFAULT '{}'
        CHECK (jsonb_typeof(spatial_metadata) = 'object'),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (project_id, name)
);

CREATE TABLE IF NOT EXISTS units (
    id SERIAL PRIMARY KEY,
    property_id INTEGER NOT NULL REFERENCES properties (id) ON DELETE CASCADE,
    code VARCHAR(40) NOT NULL,
    name VARCHAR(160) NOT NULL,
    floor_level INTEGER NOT NULL DEFAULT 0,
    status VARCHAR(20) NOT NULL DEFAULT 'available'
        CHECK (status IN ('available', 'reserved', 'sold', 'under_renovation')),
    price NUMERIC(14, 2) CHECK (price >= 0),
    currency CHAR(3) NOT NULL DEFAULT 'USD' CHECK (currency = upper(currency)),
    area_m2 NUMERIC(10, 2) CHECK (area_m2 > 0),
    model_asset_ref VARCHAR(500),
    asset_config JSONB NOT NULL DEFAULT '{}'
        CHECK (jsonb_typeof(asset_config) = 'object'),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (property_id, code)
);

ALTER TABLE rooms
    ADD COLUMN IF NOT EXISTS unit_id INTEGER REFERENCES units (id) ON DELETE SET NULL,
    ADD COLUMN IF NOT EXISTS category VARCHAR(20) NOT NULL DEFAULT 'other'
        CHECK (category IN (
            'master_bedroom', 'bedroom', 'living_dining', 'kitchen', 'bathroom', 'study',
            'circulation', 'service', 'garage', 'commercial', 'other'
        )),
    ADD COLUMN IF NOT EXISTS mesh_ref VARCHAR(500);

CREATE INDEX IF NOT EXISTS idx_rooms_unit_id ON rooms (unit_id) WHERE unit_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_rooms_footprint ON rooms
    USING gist (box(point(x_m, y_m), point(x_m + width_m, y_m + depth_m)));
