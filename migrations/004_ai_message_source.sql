ALTER TABLE ai_messages ADD COLUMN source VARCHAR(10) CHECK (source IN ('ai', 'rules'));
