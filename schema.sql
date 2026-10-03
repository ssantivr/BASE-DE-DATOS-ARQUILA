CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    name VARCHAR(120) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

ALTER TABLE users ADD COLUMN IF NOT EXISTS password_hash VARCHAR(255);

CREATE TABLE IF NOT EXISTS user_sessions (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    token_hash VARCHAR(64) UNIQUE NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP NOT NULL
);

CREATE TABLE IF NOT EXISTS projects (
    id SERIAL PRIMARY KEY,
    owner_id INTEGER NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    name VARCHAR(160) NOT NULL,
    description TEXT,
    location VARCHAR(255),
    status VARCHAR(20) NOT NULL DEFAULT 'draft'
        CHECK (status IN ('draft', 'active', 'archived')),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (owner_id, name)
);

CREATE TABLE IF NOT EXISTS terrains (
    id SERIAL PRIMARY KEY,
    project_id INTEGER NOT NULL REFERENCES projects (id) ON DELETE CASCADE,
    name VARCHAR(160) NOT NULL,
    area_m2 NUMERIC(12, 2) NOT NULL CHECK (area_m2 > 0),
    width_m NUMERIC(8, 2) CHECK (width_m > 0),
    length_m NUMERIC(8, 2) CHECK (length_m > 0),
    slope_percent NUMERIC(5, 2) CHECK (slope_percent >= 0),
    soil_type VARCHAR(80),
    latitude NUMERIC(9, 6) CHECK (latitude BETWEEN -90 AND 90),
    longitude NUMERIC(9, 6) CHECK (longitude BETWEEN -180 AND 180),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

ALTER TABLE terrains ADD COLUMN IF NOT EXISTS width_m NUMERIC(8, 2) CHECK (width_m > 0);
ALTER TABLE terrains ADD COLUMN IF NOT EXISTS length_m NUMERIC(8, 2) CHECK (length_m > 0);

CREATE TABLE IF NOT EXISTS files (
    id SERIAL PRIMARY KEY,
    project_id INTEGER NOT NULL REFERENCES projects (id) ON DELETE CASCADE,
    uploaded_by INTEGER REFERENCES users (id) ON DELETE SET NULL,
    filename VARCHAR(255) NOT NULL,
    storage_path VARCHAR(500) NOT NULL,
    mime_type VARCHAR(120) NOT NULL,
    size_bytes BIGINT NOT NULL CHECK (size_bytes >= 0),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS plans (
    id SERIAL PRIMARY KEY,
    project_id INTEGER NOT NULL REFERENCES projects (id) ON DELETE CASCADE,
    file_id INTEGER REFERENCES files (id) ON DELETE SET NULL,
    title VARCHAR(160) NOT NULL,
    level VARCHAR(60),
    scale VARCHAR(20),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS elevations (
    id SERIAL PRIMARY KEY,
    project_id INTEGER NOT NULL REFERENCES projects (id) ON DELETE CASCADE,
    file_id INTEGER REFERENCES files (id) ON DELETE SET NULL,
    title VARCHAR(160) NOT NULL,
    orientation VARCHAR(10) NOT NULL
        CHECK (orientation IN ('north', 'south', 'east', 'west')),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS materials (
    id SERIAL PRIMARY KEY,
    project_id INTEGER NOT NULL REFERENCES projects (id) ON DELETE CASCADE,
    name VARCHAR(160) NOT NULL,
    category VARCHAR(80),
    unit VARCHAR(20) NOT NULL,
    quantity NUMERIC(12, 2) NOT NULL DEFAULT 0 CHECK (quantity >= 0),
    unit_cost NUMERIC(12, 2) NOT NULL DEFAULT 0 CHECK (unit_cost >= 0),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (project_id, name)
);

CREATE TABLE IF NOT EXISTS recommendations (
    id SERIAL PRIMARY KEY,
    project_id INTEGER NOT NULL REFERENCES projects (id) ON DELETE CASCADE,
    category VARCHAR(80) NOT NULL,
    content TEXT NOT NULL,
    source VARCHAR(10) NOT NULL DEFAULT 'ai'
        CHECK (source IN ('ai', 'user', 'system')),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS ai_conversations (
    id SERIAL PRIMARY KEY,
    project_id INTEGER NOT NULL REFERENCES projects (id) ON DELETE CASCADE,
    user_id INTEGER NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    title VARCHAR(160),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS ai_messages (
    id SERIAL PRIMARY KEY,
    conversation_id INTEGER NOT NULL REFERENCES ai_conversations (id) ON DELETE CASCADE,
    role VARCHAR(10) NOT NULL
        CHECK (role IN ('user', 'assistant', 'system')),
    content TEXT NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_user_sessions_user_id ON user_sessions (user_id);
CREATE INDEX IF NOT EXISTS idx_projects_owner_id ON projects (owner_id);
CREATE INDEX IF NOT EXISTS idx_terrains_project_id ON terrains (project_id);
CREATE INDEX IF NOT EXISTS idx_files_project_id ON files (project_id);
CREATE INDEX IF NOT EXISTS idx_plans_project_id ON plans (project_id);
CREATE INDEX IF NOT EXISTS idx_elevations_project_id ON elevations (project_id);
CREATE INDEX IF NOT EXISTS idx_materials_project_id ON materials (project_id);
CREATE INDEX IF NOT EXISTS idx_recommendations_project_id ON recommendations (project_id);
CREATE INDEX IF NOT EXISTS idx_ai_conversations_project_id ON ai_conversations (project_id);
CREATE INDEX IF NOT EXISTS idx_ai_messages_conversation_id ON ai_messages (conversation_id);
