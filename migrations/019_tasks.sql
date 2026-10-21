CREATE TABLE IF NOT EXISTS tasks (
    id SERIAL PRIMARY KEY,
    project_id INTEGER NOT NULL REFERENCES projects (id) ON DELETE CASCADE,
    title VARCHAR(160) NOT NULL,
    description TEXT,
    status VARCHAR(20) NOT NULL DEFAULT 'todo'
        CHECK (status IN ('todo', 'in_progress', 'done')),
    assignee_id INTEGER REFERENCES users (id) ON DELETE SET NULL,
    due_date DATE,
    progress SMALLINT NOT NULL DEFAULT 0 CHECK (progress BETWEEN 0 AND 100),
    created_by INTEGER REFERENCES users (id) ON DELETE SET NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CHECK (status <> 'done' OR progress = 100)
);

CREATE INDEX IF NOT EXISTS idx_tasks_project_status ON tasks (project_id, status);

CREATE INDEX IF NOT EXISTS idx_tasks_project_due_date
    ON tasks (project_id, due_date) WHERE due_date IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_tasks_assignee_id
    ON tasks (assignee_id) WHERE assignee_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_tasks_created_by
    ON tasks (created_by) WHERE created_by IS NOT NULL;

CREATE OR REPLACE TRIGGER trg_tasks_updated_at
    BEFORE UPDATE ON tasks FOR EACH ROW EXECUTE FUNCTION set_updated_at();
