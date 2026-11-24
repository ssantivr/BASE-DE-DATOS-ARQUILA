-- What the AI read in an uploaded PDF or PNG, and what it changed, so it can be undone (R08).
SET LOCAL lock_timeout = '5s';

CREATE TABLE IF NOT EXISTS ai_extractions (
    id SERIAL PRIMARY KEY,
    -- Not CASCADE: the daily quota counts these rows, and deleting a project must not reset it.
    project_id INTEGER REFERENCES projects (id) ON DELETE SET NULL,
    file_id INTEGER REFERENCES files (id) ON DELETE SET NULL,
    user_id INTEGER NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    status VARCHAR(10) NOT NULL DEFAULT 'review'
        CONSTRAINT ai_extractions_status_known
        CHECK (status IN ('review', 'applied', 'undone', 'failed')),
    -- JSON written by the backend: the proposal, and the snapshot taken before applying it.
    proposal TEXT,
    snapshot TEXT,
    -- UTC, like the backend writes it (R18).
    created_at TIMESTAMP NOT NULL DEFAULT (now() AT TIME ZONE 'UTC')
);

CREATE INDEX IF NOT EXISTS idx_ai_extractions_project_id ON ai_extractions (project_id);
CREATE INDEX IF NOT EXISTS idx_ai_extractions_user_id_created_at
    ON ai_extractions (user_id, created_at);
