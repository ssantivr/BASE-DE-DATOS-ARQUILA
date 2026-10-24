-- A profile picture belongs to its user, not to a project: such a file has no
-- project_id and is owned through uploaded_by (indexed since 016).
ALTER TABLE files ALTER COLUMN project_id DROP NOT NULL;
