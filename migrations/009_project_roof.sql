ALTER TABLE projects ADD COLUMN roof VARCHAR(10) NOT NULL DEFAULT 'gable'
    CHECK (roof IN ('gable', 'flat'));
