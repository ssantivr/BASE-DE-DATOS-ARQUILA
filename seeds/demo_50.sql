-- 50 demo projects for the test accounts (R04). Load it with scripts/seed_demo_50.sh only.
-- The same input always gives the same rows, and running it again restores what is missing.
-- City centres: English Wikipedia, page coordinates read on 2026-11-22 (docs/DEMO_DATA.md).

-- One statement: without the mark nothing in this file runs, whatever the psql options.
DO $seed$
BEGIN
    IF current_setting('arquila.environment', true) IS DISTINCT FROM 'local' THEN
        RAISE EXCEPTION 'Refused: test data needs a database marked as local';
    END IF;

CREATE TEMP TABLE demo_projects ON COMMIT DROP AS
WITH cities (city_no, city, latitude, longitude) AS (
    VALUES
        (0, 'Quito', -0.220000, -78.512500),
        (1, 'Guayaquil', -2.190000, -79.887500),
        (2, 'Cuenca', -2.897414, -79.004481),
        (3, 'Loja', -3.983333, -79.200000),
        (4, 'Manta', -0.950022, -80.716200),
        (5, 'Riobamba', -1.673056, -78.648333),
        (6, 'Ibarra', 0.362678, -78.130667),
        (7, 'Machala', -3.266667, -79.966667),
        (8, 'Portoviejo', -1.056111, -80.455278)
),
kinds (kind_no, kind, summary) AS (
    VALUES
        (0, 'Casa', 'Vivienda unifamiliar con patio y zona social abierta.'),
        (1, 'Edificio', 'Vivienda colectiva con comercio en planta baja.'),
        (2, 'Consultorio', 'Consultorio médico con recepción y sala de espera.'),
        (3, 'Escuela', 'Aulas, biblioteca y patio cubierto para una escuela pequeña.'),
        (4, 'Oficinas', 'Oficinas con puestos compartidos y sala de reuniones.'),
        (5, 'Cafetería', 'Cafetería con cocina, barra y terraza.'),
        (6, 'Taller', 'Taller con área de trabajo y bodega.')
)
SELECT
    n,
    CASE
        WHEN n <= 20 THEN 'architect@example.com'
        WHEN n <= 40 THEN 'admin@example.com'
        ELSE 'viewer@example.com'
    END AS email,
    format('%s %s %s', k.kind, c.city, lpad(n::text, 2, '0')) AS name,
    k.summary AS description,
    c.city || ', Ecuador' AS location,
    c.latitude,
    c.longitude,
    (ARRAY['active', 'active', 'draft', 'active', 'archived', 'draft'])[n % 6 + 1] AS status,
    (12 + n % 9)::numeric AS lot_width,
    (20 + n % 11)::numeric AS lot_length,
    1 + n % 2 AS levels
FROM generate_series(1, 50) AS n
JOIN cities c ON c.city_no = n % 9
JOIN kinds k ON k.kind_no = n % 7;

INSERT INTO projects (owner_id, name, description, location, status, latitude, longitude, location_zoom)
SELECT u.id, d.name, d.description, d.location, d.status, d.latitude, d.longitude, 13
FROM demo_projects d
JOIN users u ON u.email = d.email
ORDER BY d.n
ON CONFLICT (owner_id, name) DO NOTHING;

CREATE TEMP TABLE demo_ids ON COMMIT DROP AS
SELECT p.id AS project_id, d.*
FROM demo_projects d
JOIN users u ON u.email = d.email
JOIN projects p ON p.owner_id = u.id AND p.name = d.name;

-- The lot has no coordinates of its own: only the centre of the city is known.
INSERT INTO terrains (project_id, name, area_m2, width_m, length_m)
SELECT d.project_id, 'Lote principal', d.lot_width * d.lot_length, d.lot_width, d.lot_length
FROM demo_ids d
WHERE NOT EXISTS (
    SELECT 1 FROM terrains t WHERE t.project_id = d.project_id AND t.name = 'Lote principal'
);

INSERT INTO plans (project_id, title, level, scale)
SELECT d.project_id, format('Planta %s', level_no), level_no::text, '1:100'
FROM demo_ids d
CROSS JOIN LATERAL generate_series(1, d.levels) AS level_no
WHERE NOT EXISTS (
    SELECT 1 FROM plans p
    WHERE p.project_id = d.project_id AND p.title = format('Planta %s', level_no)
)
ORDER BY d.n, level_no;

-- Four rooms on each plan, side by side inside the lot.
INSERT INTO rooms (project_id, plan_id, name, x_m, y_m, width_m, depth_m, height_m)
SELECT d.project_id, p.id, r.name, r.x_m, r.y_m, 4, 5, 3
FROM demo_ids d
JOIN plans p ON p.project_id = d.project_id AND p.title IN ('Planta 1', 'Planta 2')
CROSS JOIN (
    VALUES
        ('Acceso', 2, 2),
        ('Área principal', 6, 2),
        ('Servicios', 2, 7),
        ('Circulación', 6, 7)
) AS r (name, x_m, y_m)
WHERE NOT EXISTS (
    SELECT 1 FROM rooms x WHERE x.plan_id = p.id AND x.name = r.name
)
ORDER BY d.n, p.id, r.name;

INSERT INTO structural_components (project_id, plan_id, kind, name, x_m, y_m, width_m, depth_m, height_m)
SELECT d.project_id, p.id, 'column', c.name, c.x_m, c.y_m, 0.3, 0.3, 3
FROM demo_ids d
JOIN plans p ON p.project_id = d.project_id AND p.title = 'Planta 1'
CROSS JOIN (
    VALUES
        ('Columna A1', 2, 2),
        ('Columna B1', 9.7, 2),
        ('Columna A2', 2, 11.7),
        ('Columna B2', 9.7, 11.7)
) AS c (name, x_m, y_m)
WHERE NOT EXISTS (
    SELECT 1 FROM structural_components x WHERE x.plan_id = p.id AND x.name = c.name
);
END
$seed$;
