ALTER TABLE recommendations ADD COLUMN priority VARCHAR(10) NOT NULL DEFAULT 'medium'
    CHECK (priority IN ('high', 'medium', 'low'));
