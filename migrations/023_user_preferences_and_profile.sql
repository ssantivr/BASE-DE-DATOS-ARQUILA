ALTER TABLE users
    ADD COLUMN IF NOT EXISTS display_name VARCHAR(120),
    ADD COLUMN IF NOT EXISTS avatar_file_id INTEGER REFERENCES files (id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_users_avatar_file_id
    ON users (avatar_file_id) WHERE avatar_file_id IS NOT NULL;

CREATE TABLE IF NOT EXISTS user_preferences (
    user_id INTEGER PRIMARY KEY REFERENCES users (id) ON DELETE CASCADE,
    theme VARCHAR(10) NOT NULL DEFAULT 'auto'
        CHECK (theme IN ('light', 'dark', 'auto')),
    units VARCHAR(10) NOT NULL DEFAULT 'metric'
        CHECK (units IN ('metric', 'imperial')),
    density VARCHAR(20) NOT NULL DEFAULT 'comfortable'
        CHECK (density IN ('compact', 'comfortable', 'spacious')),
    reduce_motion BOOLEAN NOT NULL DEFAULT FALSE,
    camera_defaults JSONB NOT NULL DEFAULT '{}'
        CHECK (jsonb_typeof(camera_defaults) = 'object'),
    preview_quality VARCHAR(10) NOT NULL DEFAULT 'medium'
        CHECK (preview_quality IN ('low', 'medium', 'high')),
    notifications JSONB NOT NULL DEFAULT '{}'
        CHECK (jsonb_typeof(notifications) = 'object'),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE OR REPLACE TRIGGER trg_user_preferences_updated_at
    BEFORE UPDATE ON user_preferences FOR EACH ROW EXECUTE FUNCTION set_updated_at();
