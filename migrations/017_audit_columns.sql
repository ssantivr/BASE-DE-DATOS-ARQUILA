-- Keeps updated_at current on every UPDATE. If the statement already sets a new
-- value (the ORM does, with onupdate), that value is kept.
CREATE OR REPLACE FUNCTION set_updated_at() RETURNS trigger AS $$
BEGIN
    IF NEW.updated_at IS NOT DISTINCT FROM OLD.updated_at THEN
        NEW.updated_at := CURRENT_TIMESTAMP;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- updated_at: existing rows take their created_at, the last date known for them.
ALTER TABLE users ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP;
ALTER TABLE terrains ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP;
ALTER TABLE plans ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP;
ALTER TABLE elevations ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP;
ALTER TABLE materials ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP;
ALTER TABLE recommendations ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP;
ALTER TABLE ai_conversations ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP;
ALTER TABLE rooms ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP;
ALTER TABLE structural_components ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP;
ALTER TABLE spatial_elements ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP;
ALTER TABLE walkthrough_steps ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP;

UPDATE users SET updated_at = created_at WHERE updated_at IS NULL;
UPDATE terrains SET updated_at = created_at WHERE updated_at IS NULL;
UPDATE plans SET updated_at = created_at WHERE updated_at IS NULL;
UPDATE elevations SET updated_at = created_at WHERE updated_at IS NULL;
UPDATE materials SET updated_at = created_at WHERE updated_at IS NULL;
UPDATE recommendations SET updated_at = created_at WHERE updated_at IS NULL;
UPDATE ai_conversations SET updated_at = created_at WHERE updated_at IS NULL;
UPDATE rooms SET updated_at = created_at WHERE updated_at IS NULL;
UPDATE structural_components SET updated_at = created_at WHERE updated_at IS NULL;
UPDATE spatial_elements SET updated_at = created_at WHERE updated_at IS NULL;
UPDATE walkthrough_steps SET updated_at = created_at WHERE updated_at IS NULL;

ALTER TABLE users ALTER COLUMN updated_at SET DEFAULT CURRENT_TIMESTAMP, ALTER COLUMN updated_at SET NOT NULL;
ALTER TABLE terrains ALTER COLUMN updated_at SET DEFAULT CURRENT_TIMESTAMP, ALTER COLUMN updated_at SET NOT NULL;
ALTER TABLE plans ALTER COLUMN updated_at SET DEFAULT CURRENT_TIMESTAMP, ALTER COLUMN updated_at SET NOT NULL;
ALTER TABLE elevations ALTER COLUMN updated_at SET DEFAULT CURRENT_TIMESTAMP, ALTER COLUMN updated_at SET NOT NULL;
ALTER TABLE materials ALTER COLUMN updated_at SET DEFAULT CURRENT_TIMESTAMP, ALTER COLUMN updated_at SET NOT NULL;
ALTER TABLE recommendations ALTER COLUMN updated_at SET DEFAULT CURRENT_TIMESTAMP, ALTER COLUMN updated_at SET NOT NULL;
ALTER TABLE ai_conversations ALTER COLUMN updated_at SET DEFAULT CURRENT_TIMESTAMP, ALTER COLUMN updated_at SET NOT NULL;
ALTER TABLE rooms ALTER COLUMN updated_at SET DEFAULT CURRENT_TIMESTAMP, ALTER COLUMN updated_at SET NOT NULL;
ALTER TABLE structural_components ALTER COLUMN updated_at SET DEFAULT CURRENT_TIMESTAMP, ALTER COLUMN updated_at SET NOT NULL;
ALTER TABLE spatial_elements ALTER COLUMN updated_at SET DEFAULT CURRENT_TIMESTAMP, ALTER COLUMN updated_at SET NOT NULL;
ALTER TABLE walkthrough_steps ALTER COLUMN updated_at SET DEFAULT CURRENT_TIMESTAMP, ALTER COLUMN updated_at SET NOT NULL;

-- created_at: the vertices of a lot take the date of their lot.
ALTER TABLE terrain_points ADD COLUMN IF NOT EXISTS created_at TIMESTAMP;

UPDATE terrain_points tp
SET created_at = t.created_at
FROM terrains t
WHERE t.id = tp.terrain_id
  AND tp.created_at IS NULL;

ALTER TABLE terrain_points
    ALTER COLUMN created_at SET DEFAULT CURRENT_TIMESTAMP,
    ALTER COLUMN created_at SET NOT NULL;

-- created_by: unknown for existing rows, except projects, created by their owner.
ALTER TABLE projects ADD COLUMN IF NOT EXISTS created_by INTEGER REFERENCES users (id) ON DELETE SET NULL;
ALTER TABLE terrains ADD COLUMN IF NOT EXISTS created_by INTEGER REFERENCES users (id) ON DELETE SET NULL;
ALTER TABLE plans ADD COLUMN IF NOT EXISTS created_by INTEGER REFERENCES users (id) ON DELETE SET NULL;
ALTER TABLE elevations ADD COLUMN IF NOT EXISTS created_by INTEGER REFERENCES users (id) ON DELETE SET NULL;
ALTER TABLE materials ADD COLUMN IF NOT EXISTS created_by INTEGER REFERENCES users (id) ON DELETE SET NULL;
ALTER TABLE recommendations ADD COLUMN IF NOT EXISTS created_by INTEGER REFERENCES users (id) ON DELETE SET NULL;
ALTER TABLE rooms ADD COLUMN IF NOT EXISTS created_by INTEGER REFERENCES users (id) ON DELETE SET NULL;
ALTER TABLE structural_components ADD COLUMN IF NOT EXISTS created_by INTEGER REFERENCES users (id) ON DELETE SET NULL;
ALTER TABLE spatial_elements ADD COLUMN IF NOT EXISTS created_by INTEGER REFERENCES users (id) ON DELETE SET NULL;
ALTER TABLE walkthrough_steps ADD COLUMN IF NOT EXISTS created_by INTEGER REFERENCES users (id) ON DELETE SET NULL;
ALTER TABLE properties ADD COLUMN IF NOT EXISTS created_by INTEGER REFERENCES users (id) ON DELETE SET NULL;
ALTER TABLE units ADD COLUMN IF NOT EXISTS created_by INTEGER REFERENCES users (id) ON DELETE SET NULL;

UPDATE projects SET created_by = owner_id WHERE created_by IS NULL;

CREATE INDEX IF NOT EXISTS idx_projects_created_by
    ON projects (created_by) WHERE created_by IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_terrains_created_by
    ON terrains (created_by) WHERE created_by IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_plans_created_by
    ON plans (created_by) WHERE created_by IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_elevations_created_by
    ON elevations (created_by) WHERE created_by IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_materials_created_by
    ON materials (created_by) WHERE created_by IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_recommendations_created_by
    ON recommendations (created_by) WHERE created_by IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_rooms_created_by
    ON rooms (created_by) WHERE created_by IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_structural_components_created_by
    ON structural_components (created_by) WHERE created_by IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_spatial_elements_created_by
    ON spatial_elements (created_by) WHERE created_by IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_walkthrough_steps_created_by
    ON walkthrough_steps (created_by) WHERE created_by IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_properties_created_by
    ON properties (created_by) WHERE created_by IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_units_created_by
    ON units (created_by) WHERE created_by IS NOT NULL;

-- The triggers go last so that the backfill above does not touch updated_at.
CREATE OR REPLACE TRIGGER trg_users_updated_at
    BEFORE UPDATE ON users FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE OR REPLACE TRIGGER trg_projects_updated_at
    BEFORE UPDATE ON projects FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE OR REPLACE TRIGGER trg_terrains_updated_at
    BEFORE UPDATE ON terrains FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE OR REPLACE TRIGGER trg_plans_updated_at
    BEFORE UPDATE ON plans FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE OR REPLACE TRIGGER trg_elevations_updated_at
    BEFORE UPDATE ON elevations FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE OR REPLACE TRIGGER trg_materials_updated_at
    BEFORE UPDATE ON materials FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE OR REPLACE TRIGGER trg_recommendations_updated_at
    BEFORE UPDATE ON recommendations FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE OR REPLACE TRIGGER trg_ai_conversations_updated_at
    BEFORE UPDATE ON ai_conversations FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE OR REPLACE TRIGGER trg_rooms_updated_at
    BEFORE UPDATE ON rooms FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE OR REPLACE TRIGGER trg_structural_components_updated_at
    BEFORE UPDATE ON structural_components FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE OR REPLACE TRIGGER trg_properties_updated_at
    BEFORE UPDATE ON properties FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE OR REPLACE TRIGGER trg_units_updated_at
    BEFORE UPDATE ON units FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE OR REPLACE TRIGGER trg_spatial_elements_updated_at
    BEFORE UPDATE ON spatial_elements FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE OR REPLACE TRIGGER trg_walkthrough_steps_updated_at
    BEFORE UPDATE ON walkthrough_steps FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE OR REPLACE TRIGGER trg_renovation_logs_updated_at
    BEFORE UPDATE ON renovation_logs FOR EACH ROW EXECUTE FUNCTION set_updated_at();
