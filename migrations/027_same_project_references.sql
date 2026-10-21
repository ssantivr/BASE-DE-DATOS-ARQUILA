-- A row can only point at plans, rooms, spatial elements and files of its own project.
-- Until now only the backend checked it; composite foreign keys (column, project_id) make
-- the database refuse a reference to another project's row.
--
-- The single-column foreign keys stay as they are: the composite ones are added beside them.
-- MATCH SIMPLE (the default) skips a composite key whose column is NULL, so the optional
-- references keep working. ON DELETE SET NULL (column) needs PostgreSQL 15 or later: it
-- empties only the reference, never project_id, which is NOT NULL.

-- Stop with the list of what would break, instead of failing at the first constraint.
DO $$
DECLARE
    report TEXT;
BEGIN
    SELECT string_agg(reference || ': ' || crossed, ', ')
    INTO report
    FROM (
        SELECT 'rooms.plan_id' AS reference, count(*) AS crossed
        FROM rooms r JOIN plans p ON p.id = r.plan_id
        WHERE p.project_id <> r.project_id
        UNION ALL
        SELECT 'structural_components.plan_id', count(*)
        FROM structural_components c JOIN plans p ON p.id = c.plan_id
        WHERE p.project_id <> c.project_id
        UNION ALL
        SELECT 'spatial_elements.room_id', count(*)
        FROM spatial_elements e JOIN rooms r ON r.id = e.room_id
        WHERE r.project_id <> e.project_id
        UNION ALL
        SELECT 'walkthrough_steps.room_id', count(*)
        FROM walkthrough_steps w JOIN rooms r ON r.id = w.room_id
        WHERE r.project_id <> w.project_id
        UNION ALL
        SELECT 'renovation_logs.room_id', count(*)
        FROM renovation_logs l JOIN rooms r ON r.id = l.room_id
        WHERE r.project_id <> l.project_id
        UNION ALL
        SELECT 'renovation_logs.spatial_element_id', count(*)
        FROM renovation_logs l JOIN spatial_elements e ON e.id = l.spatial_element_id
        WHERE e.project_id <> l.project_id
        UNION ALL
        SELECT 'plans.file_id', count(*)
        FROM plans p JOIN files f ON f.id = p.file_id
        WHERE f.project_id IS DISTINCT FROM p.project_id
        UNION ALL
        SELECT 'elevations.file_id', count(*)
        FROM elevations e JOIN files f ON f.id = e.file_id
        WHERE f.project_id IS DISTINCT FROM e.project_id
        UNION ALL
        SELECT 'projects.cover_file_id', count(*)
        FROM projects p JOIN files f ON f.id = p.cover_file_id
        WHERE f.project_id IS DISTINCT FROM p.id
    ) AS checks
    WHERE crossed > 0;

    -- No format placeholder here: app/migrate.py runs this file through psycopg, which would
    -- take the percent sign of RAISE for a parameter of its own.
    IF report IS NOT NULL THEN
        RAISE EXCEPTION USING
            MESSAGE = 'Rows that point at another project: ' || report,
            HINT = 'Fix or empty those references, then run the migration again.';
    END IF;
END
$$;

-- Targets of the composite keys.
ALTER TABLE plans ADD CONSTRAINT uq_plans_id_project UNIQUE (id, project_id);
ALTER TABLE rooms ADD CONSTRAINT uq_rooms_id_project UNIQUE (id, project_id);
ALTER TABLE spatial_elements ADD CONSTRAINT uq_spatial_elements_id_project UNIQUE (id, project_id);
ALTER TABLE files ADD CONSTRAINT uq_files_id_project UNIQUE (id, project_id);

-- A room and a component go with their plan, as they already did.
ALTER TABLE rooms ADD CONSTRAINT fk_rooms_plan_same_project
    FOREIGN KEY (plan_id, project_id) REFERENCES plans (id, project_id) ON DELETE CASCADE;

ALTER TABLE structural_components ADD CONSTRAINT fk_structural_components_plan_same_project
    FOREIGN KEY (plan_id, project_id) REFERENCES plans (id, project_id) ON DELETE CASCADE;

-- The optional references are emptied when their target goes, as they already were.
ALTER TABLE spatial_elements ADD CONSTRAINT fk_spatial_elements_room_same_project
    FOREIGN KEY (room_id, project_id) REFERENCES rooms (id, project_id)
    ON DELETE SET NULL (room_id);

ALTER TABLE walkthrough_steps ADD CONSTRAINT fk_walkthrough_steps_room_same_project
    FOREIGN KEY (room_id, project_id) REFERENCES rooms (id, project_id)
    ON DELETE SET NULL (room_id);

ALTER TABLE renovation_logs ADD CONSTRAINT fk_renovation_logs_room_same_project
    FOREIGN KEY (room_id, project_id) REFERENCES rooms (id, project_id)
    ON DELETE SET NULL (room_id);

ALTER TABLE renovation_logs ADD CONSTRAINT fk_renovation_logs_spatial_element_same_project
    FOREIGN KEY (spatial_element_id, project_id) REFERENCES spatial_elements (id, project_id)
    ON DELETE SET NULL (spatial_element_id);

-- A file without a project (a profile picture, since 026) cannot be a plan, an elevation or a
-- cover: its project_id is NULL, so it matches no (id, project_id) of a project.
ALTER TABLE plans ADD CONSTRAINT fk_plans_file_same_project
    FOREIGN KEY (file_id, project_id) REFERENCES files (id, project_id)
    ON DELETE SET NULL (file_id);

ALTER TABLE elevations ADD CONSTRAINT fk_elevations_file_same_project
    FOREIGN KEY (file_id, project_id) REFERENCES files (id, project_id)
    ON DELETE SET NULL (file_id);

ALTER TABLE projects ADD CONSTRAINT fk_projects_cover_same_project
    FOREIGN KEY (cover_file_id, id) REFERENCES files (id, project_id)
    ON DELETE SET NULL (cover_file_id);
