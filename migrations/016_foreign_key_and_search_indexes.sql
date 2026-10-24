CREATE INDEX IF NOT EXISTS idx_files_uploaded_by
    ON files (uploaded_by) WHERE uploaded_by IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_plans_file_id
    ON plans (file_id) WHERE file_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_elevations_file_id
    ON elevations (file_id) WHERE file_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_ai_conversations_user_id ON ai_conversations (user_id);

CREATE INDEX IF NOT EXISTS idx_ai_messages_conversation_created
    ON ai_messages (conversation_id, created_at);

CREATE INDEX IF NOT EXISTS idx_projects_owner_status ON projects (owner_id, status);

CREATE INDEX IF NOT EXISTS idx_projects_owner_updated_at ON projects (owner_id, updated_at DESC);

CREATE INDEX IF NOT EXISTS idx_properties_status ON properties (status);

CREATE INDEX IF NOT EXISTS idx_units_property_status ON units (property_id, status);

CREATE INDEX IF NOT EXISTS idx_user_sessions_expires_at ON user_sessions (expires_at);

CREATE INDEX IF NOT EXISTS idx_password_reset_tokens_expires_at ON password_reset_tokens (expires_at);
