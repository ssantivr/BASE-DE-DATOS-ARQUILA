INSERT INTO users (name, email, password_hash)
VALUES ('Demo User', 'demo@example.com', '$argon2id$v=19$m=65536,t=3,p=4$NpZv9xU4YHWPCPZnTY95Zw$O09hjiydM0i5bipHRfIgMAyOL4W/ugT9aFmubWaCICs')
ON CONFLICT (email) DO NOTHING;

INSERT INTO projects (owner_id, name, description, location, status)
SELECT u.id, v.name, v.description, v.location, v.status
FROM users u
CROSS JOIN (
    VALUES
        ('Casa Los Arrayanes', 'Vivienda unifamiliar de dos plantas con patio central y estacionamiento para dos vehículos.', 'Cumbayá, Quito', 'active'),
        ('Edificio Mirador', 'Edificio de cuatro pisos de uso mixto en un lote esquinero con pendiente pronunciada.', 'Loja', 'draft'),
        ('Cabaña Mindo', 'Cabaña de madera de un ambiente. Proyecto pausado a la espera del levantamiento topográfico.', 'Mindo, Pichincha', 'archived')
) AS v (name, description, location, status)
WHERE u.email = 'demo@example.com'
ON CONFLICT (owner_id, name) DO NOTHING;

INSERT INTO terrains (project_id, name, area_m2, width_m, length_m, slope_percent, soil_type, latitude, longitude)
SELECT p.id, v.name, v.area_m2, v.width_m::numeric, v.length_m::numeric, v.slope_percent::numeric,
       v.soil_type, v.latitude::numeric, v.longitude::numeric
FROM (
    VALUES
        ('Casa Los Arrayanes', 'Lote 14', 576, 18, 32, 6, 'limo arenoso', -0.2005, -78.4311),
        ('Edificio Mirador', 'Lote esquinero', 400, NULL, NULL, 22, 'arcilla', NULL, NULL),
        ('Edificio Mirador', 'Franja de acceso', 96, 6, 16, 4, NULL, NULL, NULL),
        ('Cabaña Mindo', 'Claro junto al río', 1250, NULL, NULL, NULL, NULL, NULL, NULL)
) AS v (project, name, area_m2, width_m, length_m, slope_percent, soil_type, latitude, longitude)
JOIN projects p ON p.name = v.project
JOIN users u ON u.id = p.owner_id AND u.email = 'demo@example.com'
WHERE NOT EXISTS (
    SELECT 1 FROM terrains t WHERE t.project_id = p.id AND t.name = v.name
);

INSERT INTO terrain_points (terrain_id, position, x_m, y_m)
SELECT t.id, v.position, v.x_m, v.y_m
FROM (
    VALUES
        ('Edificio Mirador', 'Lote esquinero', 0, 0, 0),
        ('Edificio Mirador', 'Lote esquinero', 1, 20, 0),
        ('Edificio Mirador', 'Lote esquinero', 2, 20, 10),
        ('Edificio Mirador', 'Lote esquinero', 3, 10, 10),
        ('Edificio Mirador', 'Lote esquinero', 4, 10, 30),
        ('Edificio Mirador', 'Lote esquinero', 5, 0, 30)
) AS v (project, terrain, position, x_m, y_m)
JOIN projects p ON p.name = v.project
JOIN users u ON u.id = p.owner_id AND u.email = 'demo@example.com'
JOIN terrains t ON t.project_id = p.id AND t.name = v.terrain
ON CONFLICT (terrain_id, position) DO NOTHING;

INSERT INTO plans (project_id, title, level, scale)
SELECT p.id, v.title, v.level, v.scale
FROM (
    VALUES
        ('Casa Los Arrayanes', 'Planta baja', '0', '1:100'),
        ('Casa Los Arrayanes', 'Planta alta', '1', '1:100'),
        ('Casa Los Arrayanes', 'Implantación', 'Terreno', '1:200'),
        ('Casa Los Arrayanes', 'Cubiertas', '2', '1:100'),
        ('Edificio Mirador', 'Planta de locales', '0', '1:100'),
        ('Edificio Mirador', 'Planta tipo', '1 a 3', '1:100'),
        ('Cabaña Mindo', 'Planta única', NULL, '1:50')
) AS v (project, title, level, scale)
JOIN projects p ON p.name = v.project
JOIN users u ON u.id = p.owner_id AND u.email = 'demo@example.com'
WHERE NOT EXISTS (
    SELECT 1 FROM plans x WHERE x.project_id = p.id AND x.title = v.title
);

INSERT INTO elevations (project_id, title, orientation)
SELECT p.id, v.title, v.orientation
FROM (
    VALUES
        ('Casa Los Arrayanes', 'Fachada frontal', 'north'),
        ('Casa Los Arrayanes', 'Fachada posterior', 'south'),
        ('Casa Los Arrayanes', 'Fachada lateral derecha', 'east'),
        ('Casa Los Arrayanes', 'Fachada lateral izquierda', 'west'),
        ('Edificio Mirador', 'Fachada a la avenida', 'east'),
        ('Edificio Mirador', 'Fachada a la calle secundaria', 'south')
) AS v (project, title, orientation)
JOIN projects p ON p.name = v.project
JOIN users u ON u.id = p.owner_id AND u.email = 'demo@example.com'
WHERE NOT EXISTS (
    SELECT 1 FROM elevations x WHERE x.project_id = p.id AND x.title = v.title
);

INSERT INTO materials (project_id, name, category, unit, quantity, unit_cost)
SELECT p.id, v.name, v.category, v.unit, v.quantity, v.unit_cost
FROM (
    VALUES
        ('Casa Los Arrayanes', 'Hormigón 210 kg/cm²', 'Estructura', 'm³', 92, 118),
        ('Casa Los Arrayanes', 'Acero de refuerzo 12 mm', 'Estructura', 'kg', 5400, 1.32),
        ('Casa Los Arrayanes', 'Bloque de 15 cm', 'Mampostería', 'u', 6800, 0.52),
        ('Casa Los Arrayanes', 'Cemento', 'Mampostería', 'saco', 310, 8.1),
        ('Casa Los Arrayanes', 'Porcelanato 60×60', 'Acabados', 'm²', 215, 21.5),
        ('Casa Los Arrayanes', 'Pintura interior', 'Acabados', 'galón', 48, 17.9),
        ('Casa Los Arrayanes', 'Ventana de aluminio', 'Carpintería', 'm²', 46, 95),
        ('Casa Los Arrayanes', 'Teja de fibrocemento', 'Cubierta', 'm²', 168, 12.4),
        ('Edificio Mirador', 'Hormigón 280 kg/cm²', 'Estructura', 'm³', 340, 132),
        ('Edificio Mirador', 'Acero de refuerzo 16 mm', 'Estructura', 'kg', 21000, 1.36),
        ('Edificio Mirador', 'Muro de contención', 'Estructura', 'm³', 58, 0),
        ('Edificio Mirador', 'Ascensor', 'Instalaciones', 'u', 1, 0),
        ('Cabaña Mindo', 'Madera de eucalipto', 'Estructura', 'm³', 14, 310),
        ('Cabaña Mindo', 'Zinc ondulado', 'Cubierta', 'm²', 62, 6.8)
) AS v (project, name, category, unit, quantity, unit_cost)
JOIN projects p ON p.name = v.project
JOIN users u ON u.id = p.owner_id AND u.email = 'demo@example.com'
ON CONFLICT (project_id, name) DO NOTHING;

INSERT INTO recommendations (project_id, category, content, source)
SELECT p.id, v.category, v.content, 'user'
FROM (
    VALUES
        ('Casa Los Arrayanes', 'Diseño', 'Orientar el área social hacia el norte para aprovechar la luz de la mañana.'),
        ('Casa Los Arrayanes', 'Normativa', 'Confirmar retiros frontal y laterales con el municipio antes de fijar la implantación.'),
        ('Cabaña Mindo', 'Topografía', 'Falta el levantamiento: no se conoce la pendiente ni el nivel máximo del río.')
) AS v (project, category, content)
JOIN projects p ON p.name = v.project
JOIN users u ON u.id = p.owner_id AND u.email = 'demo@example.com'
WHERE NOT EXISTS (
    SELECT 1 FROM recommendations x WHERE x.project_id = p.id AND x.content = v.content
);

INSERT INTO rooms (project_id, plan_id, name, x_m, y_m, width_m, depth_m, height_m)
SELECT p.id, pl.id, v.name, v.x_m, v.y_m, v.width_m, v.depth_m, 2.8
FROM (
    VALUES
        ('Casa Los Arrayanes', 'Planta baja', 'Garaje', 3, 8, 5.5, 5),
        ('Casa Los Arrayanes', 'Planta baja', 'Hall', 8.5, 8, 2, 5),
        ('Casa Los Arrayanes', 'Planta baja', 'Sala', 10.5, 8, 4.5, 5),
        ('Casa Los Arrayanes', 'Planta baja', 'Cocina', 3, 13, 4, 3),
        ('Casa Los Arrayanes', 'Planta baja', 'Comedor', 11, 13, 4, 3),
        ('Casa Los Arrayanes', 'Planta baja', 'Lavandería', 3, 16, 3, 4),
        ('Casa Los Arrayanes', 'Planta baja', 'Baño social', 6, 16, 2, 4),
        ('Casa Los Arrayanes', 'Planta baja', 'Escalera', 8, 16, 2.5, 4),
        ('Casa Los Arrayanes', 'Planta baja', 'Estudio', 10.5, 16, 4.5, 4),
        ('Casa Los Arrayanes', 'Planta alta', 'Hab. principal', 3, 8, 5.5, 5),
        ('Casa Los Arrayanes', 'Planta alta', 'Estar íntimo', 8.5, 8, 2, 5),
        ('Casa Los Arrayanes', 'Planta alta', 'Habitación 2', 10.5, 8, 4.5, 5),
        ('Casa Los Arrayanes', 'Planta alta', 'Baño principal', 3, 13, 4, 3),
        ('Casa Los Arrayanes', 'Planta alta', 'Baño', 11, 13, 4, 3),
        ('Casa Los Arrayanes', 'Planta alta', 'Habitación 3', 3, 16, 5, 4),
        ('Casa Los Arrayanes', 'Planta alta', 'Escalera', 8, 16, 2.5, 4),
        ('Casa Los Arrayanes', 'Planta alta', 'Habitación 4', 10.5, 16, 4.5, 4)
) AS v (project, plan, name, x_m, y_m, width_m, depth_m)
JOIN projects p ON p.name = v.project
JOIN users u ON u.id = p.owner_id AND u.email = 'demo@example.com'
JOIN plans pl ON pl.project_id = p.id AND pl.title = v.plan
WHERE NOT EXISTS (
    SELECT 1 FROM rooms x WHERE x.plan_id = pl.id AND x.name = v.name
);

INSERT INTO structural_components (project_id, plan_id, kind, name, x_m, y_m, width_m, depth_m, height_m)
SELECT p.id, pl.id, 'column', v.name, v.x_m, v.y_m, 0.3, 0.3, 2.8
FROM (
    VALUES
        ('C1', 3, 8),
        ('C2', 14.7, 8),
        ('C3', 14.7, 19.7),
        ('C4', 3, 19.7),
        ('C5', 7, 13),
        ('C6', 10.7, 13),
        ('C7', 10.7, 15.7),
        ('C8', 7, 15.7)
) AS v (name, x_m, y_m)
CROSS JOIN (VALUES ('Planta baja'), ('Planta alta')) AS l (plan)
JOIN projects p ON p.name = 'Casa Los Arrayanes'
JOIN users u ON u.id = p.owner_id AND u.email = 'demo@example.com'
JOIN plans pl ON pl.project_id = p.id AND pl.title = l.plan
WHERE NOT EXISTS (
    SELECT 1 FROM structural_components x WHERE x.plan_id = pl.id AND x.name = v.name
);

INSERT INTO structural_components (project_id, plan_id, kind, name, x_m, y_m, width_m, depth_m, height_m)
SELECT p.id, pl.id, 'beam', v.name, v.x_m, v.y_m, v.width_m, v.depth_m, 0.4
FROM (
    VALUES
        ('V1', 7, 13, 4, 0.3),
        ('V2', 7, 15.7, 4, 0.3),
        ('V3', 7, 13, 0.3, 3),
        ('V4', 10.7, 13, 0.3, 3)
) AS v (name, x_m, y_m, width_m, depth_m)
CROSS JOIN (VALUES ('Planta baja'), ('Planta alta')) AS l (plan)
JOIN projects p ON p.name = 'Casa Los Arrayanes'
JOIN users u ON u.id = p.owner_id AND u.email = 'demo@example.com'
JOIN plans pl ON pl.project_id = p.id AND pl.title = l.plan
WHERE NOT EXISTS (
    SELECT 1 FROM structural_components x WHERE x.plan_id = pl.id AND x.name = v.name
);

INSERT INTO plans (project_id, title, level, scale)
SELECT p.id, v.title, v.level, '1:100'
FROM (
    VALUES
        ('Piso 1', '1'),
        ('Piso 2', '2'),
        ('Piso 3', '3')
) AS v (title, level)
JOIN projects p ON p.name = 'Edificio Mirador'
JOIN users u ON u.id = p.owner_id AND u.email = 'demo@example.com'
WHERE NOT EXISTS (
    SELECT 1 FROM plans x WHERE x.project_id = p.id AND x.title = v.title
);

UPDATE projects p
SET roof = 'flat'
FROM users u
WHERE u.id = p.owner_id
  AND u.email = 'demo@example.com'
  AND p.name = 'Edificio Mirador'
  AND NOT EXISTS (SELECT 1 FROM rooms x WHERE x.project_id = p.id);

INSERT INTO rooms (project_id, plan_id, name, x_m, y_m, width_m, depth_m, height_m)
SELECT p.id, pl.id, v.name, v.x_m, 1.5, v.width_m, 7.5, v.height_m
FROM (
    VALUES
        ('Planta de locales', 'Local 1', 2, 5, 3.4),
        ('Planta de locales', 'Vestíbulo', 7, 3, 3.4),
        ('Planta de locales', 'Escalera y ascensor', 10, 3, 3.4),
        ('Planta de locales', 'Local 2', 13, 5, 3.4),
        ('Piso 1', 'Apto. 1A', 2, 5, 2.8),
        ('Piso 1', 'Circulación', 7, 3, 2.8),
        ('Piso 1', 'Escalera y ascensor', 10, 3, 2.8),
        ('Piso 1', 'Apto. 1B', 13, 5, 2.8),
        ('Piso 2', 'Apto. 2A', 2, 5, 2.8),
        ('Piso 2', 'Circulación', 7, 3, 2.8),
        ('Piso 2', 'Escalera y ascensor', 10, 3, 2.8),
        ('Piso 2', 'Apto. 2B', 13, 5, 2.8),
        ('Piso 3', 'Apto. 3A', 2, 5, 2.8),
        ('Piso 3', 'Circulación', 7, 3, 2.8),
        ('Piso 3', 'Escalera y ascensor', 10, 3, 2.8),
        ('Piso 3', 'Apto. 3B', 13, 5, 2.8)
) AS v (plan, name, x_m, width_m, height_m)
JOIN projects p ON p.name = 'Edificio Mirador'
JOIN users u ON u.id = p.owner_id AND u.email = 'demo@example.com'
JOIN plans pl ON pl.project_id = p.id AND pl.title = v.plan
WHERE NOT EXISTS (
    SELECT 1 FROM rooms x WHERE x.plan_id = pl.id AND x.name = v.name
);

INSERT INTO structural_components (project_id, plan_id, kind, name, x_m, y_m, width_m, depth_m, height_m)
SELECT p.id, pl.id, 'column', v.name, v.x_m, v.y_m, 0.4, 0.4, l.height_m
FROM (
    VALUES
        ('C1', 2, 1.5),
        ('C2', 9.8, 1.5),
        ('C3', 17.6, 1.5),
        ('C4', 17.6, 8.6),
        ('C5', 9.8, 8.6),
        ('C6', 2, 8.6)
) AS v (name, x_m, y_m)
CROSS JOIN (
    VALUES
        ('Planta de locales', 3.4),
        ('Piso 1', 2.8),
        ('Piso 2', 2.8),
        ('Piso 3', 2.8)
) AS l (plan, height_m)
JOIN projects p ON p.name = 'Edificio Mirador'
JOIN users u ON u.id = p.owner_id AND u.email = 'demo@example.com'
JOIN plans pl ON pl.project_id = p.id AND pl.title = l.plan
WHERE NOT EXISTS (
    SELECT 1 FROM structural_components x WHERE x.plan_id = pl.id AND x.name = v.name
);

INSERT INTO materials (project_id, name, category, unit, quantity, unit_cost)
SELECT p.id, v.name, v.category, v.unit, v.quantity, v.unit_cost
FROM (
    VALUES
        ('Casa Los Arrayanes', 'Puerta de madera', 'Carpintería', 'u', 12, 185),
        ('Casa Los Arrayanes', 'Cerámica de baño', 'Acabados', 'm²', 38, 14.6),
        ('Casa Los Arrayanes', 'Tubería PVC de 110 mm', 'Instalaciones', 'm', 85, 5.2),
        ('Casa Los Arrayanes', 'Cable eléctrico n.º 12', 'Instalaciones', 'm', 640, 0.85),
        ('Edificio Mirador', 'Bloque de 20 cm', 'Mampostería', 'u', 14500, 0.68),
        ('Edificio Mirador', 'Vidrio templado 8 mm', 'Carpintería', 'm²', 180, 62),
        ('Edificio Mirador', 'Porcelanato 60×60', 'Acabados', 'm²', 480, 21.5),
        ('Edificio Mirador', 'Impermeabilizante de losa', 'Cubierta', 'm²', 130, 9.4),
        ('Edificio Mirador', 'Tubería PVC de 110 mm', 'Instalaciones', 'm', 320, 5.2)
) AS v (project, name, category, unit, quantity, unit_cost)
JOIN projects p ON p.name = v.project
JOIN users u ON u.id = p.owner_id AND u.email = 'demo@example.com'
ON CONFLICT (project_id, name) DO NOTHING;

INSERT INTO elevations (project_id, title, orientation)
SELECT p.id, v.title, v.orientation
FROM (
    VALUES
        ('Edificio Mirador', 'Fachada norte', 'north'),
        ('Edificio Mirador', 'Fachada al lote vecino', 'west')
) AS v (project, title, orientation)
JOIN projects p ON p.name = v.project
JOIN users u ON u.id = p.owner_id AND u.email = 'demo@example.com'
WHERE NOT EXISTS (
    SELECT 1 FROM elevations x WHERE x.project_id = p.id AND x.title = v.title
);

INSERT INTO recommendations (project_id, category, content, source)
SELECT p.id, v.category, v.content, 'user'
FROM (
    VALUES
        ('Casa Los Arrayanes', 'Estructura', 'Las columnas del patio central reciben la losa de la planta alta: revisar su sección con el ingeniero estructural.'),
        ('Casa Los Arrayanes', 'Ventilación', 'El patio central permite ventilación cruzada: mantener ventanas enfrentadas en la sala y el comedor.'),
        ('Edificio Mirador', 'Estructura', 'El lote tiene una pendiente pronunciada: el muro de contención del lado alto debe diseñarse con el estudio de suelos.'),
        ('Edificio Mirador', 'Normativa', 'Verificar con el municipio la altura máxima y los retiros que aplican a un lote esquinero.')
) AS v (project, category, content)
JOIN projects p ON p.name = v.project
JOIN users u ON u.id = p.owner_id AND u.email = 'demo@example.com'
WHERE NOT EXISTS (
    SELECT 1 FROM recommendations x WHERE x.project_id = p.id AND x.content = v.content
);

INSERT INTO user_roles (user_id, role_id)
SELECT u.id, r.id
FROM users u
CROSS JOIN roles r
WHERE u.email = 'demo@example.com'
  AND r.name = 'architect'
ON CONFLICT DO NOTHING;

INSERT INTO properties (project_id, name, property_type, address, status, spatial_metadata)
SELECT p.id, 'Casa Los Arrayanes', 'house', 'Cumbayá, Quito', 'renovation',
       '{"units": "m", "up_axis": "z", "origin": "lot_corner"}'::jsonb
FROM projects p
JOIN users u ON u.id = p.owner_id AND u.email = 'demo@example.com'
WHERE p.name = 'Casa Los Arrayanes'
ON CONFLICT (project_id, name) DO NOTHING;

INSERT INTO units (property_id, code, name, floor_level, status, price, area_m2, asset_config)
SELECT pr.id, 'CASA-01', 'Vivienda principal', 0, 'under_renovation', 285000, 288,
       '{"default_view": "isometric", "layers": ["structure", "installations", "finishes"]}'::jsonb
FROM properties pr
JOIN projects p ON p.id = pr.project_id AND p.name = 'Casa Los Arrayanes'
JOIN users u ON u.id = p.owner_id AND u.email = 'demo@example.com'
ON CONFLICT (property_id, code) DO NOTHING;

UPDATE rooms r
SET unit_id = un.id, category = v.category
FROM (
    VALUES
        ('Garaje', 'garage'),
        ('Hall', 'circulation'),
        ('Sala', 'living_dining'),
        ('Cocina', 'kitchen'),
        ('Comedor', 'living_dining'),
        ('Lavandería', 'service'),
        ('Baño social', 'bathroom'),
        ('Escalera', 'circulation'),
        ('Estudio', 'study'),
        ('Hab. principal', 'master_bedroom'),
        ('Estar íntimo', 'circulation'),
        ('Habitación 2', 'bedroom'),
        ('Baño principal', 'bathroom'),
        ('Baño', 'bathroom'),
        ('Habitación 3', 'bedroom'),
        ('Habitación 4', 'bedroom')
) AS v (name, category)
JOIN projects p ON p.name = 'Casa Los Arrayanes'
JOIN users u ON u.id = p.owner_id AND u.email = 'demo@example.com'
JOIN properties pr ON pr.project_id = p.id
JOIN units un ON un.property_id = pr.id AND un.code = 'CASA-01'
WHERE r.project_id = p.id
  AND r.name = v.name
  AND r.unit_id IS NULL;

INSERT INTO spatial_elements (project_id, room_id, layer, kind, name, work_status,
                              min_x_m, min_y_m, min_z_m, max_x_m, max_y_m, max_z_m)
SELECT p.id, r.id, v.layer, v.kind, v.name, v.work_status,
       v.min_x_m, v.min_y_m, v.min_z_m, v.max_x_m, v.max_y_m, v.max_z_m
FROM (
    VALUES
        ('Sala', 'installations', 'electrical_conduit', 'Circuito de tomacorrientes de la sala', 'existing', 10.6, 8.05, 0.3, 14.9, 8.12, 0.37),
        ('Sala', 'structure', 'partition_wall', 'Muro divisorio entre sala y comedor', 'demolition', 11, 12.95, 0, 15, 13.05, 2.8),
        ('Cocina', 'installations', 'lighting', 'Riel de iluminación de la cocina', 'existing', 3.5, 14.45, 2.6, 6.5, 14.55, 2.68),
        ('Hab. principal', 'installations', 'hvac_duct', 'Ducto de aire acondicionado', 'planned', 3.2, 10.2, 5.2, 8.3, 10.7, 5.5),
        ('Hab. principal', 'finishes', 'flooring', 'Piso de madera de la habitación principal', 'planned', 3.1, 8.1, 2.8, 8.4, 12.9, 2.84),
        ('Baño principal', 'installations', 'water_pipe', 'Tubería de agua fría', 'existing', 3.1, 13.05, 3.1, 6.9, 13.15, 3.2),
        ('Baño principal', 'installations', 'drain_pipe', 'Desagüe nuevo de la ducha', 'planned', 5.5, 13.2, 2.82, 5.65, 15.8, 2.95),
        ('Baño principal', 'finishes', 'wall_cladding', 'Enchape de porcelanato', 'planned', 3.02, 13.1, 2.8, 3.08, 15.9, 5)
) AS v (room, layer, kind, name, work_status, min_x_m, min_y_m, min_z_m, max_x_m, max_y_m, max_z_m)
JOIN projects p ON p.name = 'Casa Los Arrayanes'
JOIN users u ON u.id = p.owner_id AND u.email = 'demo@example.com'
JOIN rooms r ON r.project_id = p.id AND r.name = v.room
WHERE NOT EXISTS (
    SELECT 1 FROM spatial_elements x WHERE x.project_id = p.id AND x.name = v.name
);

INSERT INTO walkthrough_steps (project_id, room_id, position, title, description, duration_ms, view_config)
SELECT p.id, r.id, v.position, v.title, v.description, v.duration_ms, v.view_config::jsonb
FROM (
    VALUES
        ('Sala', 0, 'Sala / Comedor', 'Se retira el muro divisorio para unir la sala con el comedor y se conserva el circuito eléctrico.', 7000, '{"cut_fraction": 0.8}'),
        ('Cocina', 1, 'Cocina', 'La cocina mantiene su distribución y el riel de iluminación existente.', 5000, '{"cut_fraction": 0.8}'),
        ('Hab. principal', 2, 'Habitación principal', 'Piso de madera nuevo y un ducto de aire acondicionado sobre la cabecera.', 7000, '{"cut_fraction": 0.85}'),
        ('Baño principal', 3, 'Baño principal', 'Se cambia el desagüe de la ducha y se enchapa la pared húmeda.', 6000, '{"cut_fraction": 0.8}')
) AS v (room, position, title, description, duration_ms, view_config)
JOIN projects p ON p.name = 'Casa Los Arrayanes'
JOIN users u ON u.id = p.owner_id AND u.email = 'demo@example.com'
JOIN rooms r ON r.project_id = p.id AND r.name = v.room
WHERE NOT EXISTS (
    SELECT 1 FROM walkthrough_steps x WHERE x.project_id = p.id AND x.title = v.title
);

INSERT INTO renovation_logs (project_id, room_id, spatial_element_id, created_by, layer, title,
                             description, status, planned_start, planned_end, estimated_cost)
SELECT p.id, r.id, e.id, u.id, v.layer, v.title, v.description, v.status,
       v.planned_start::date, v.planned_end::date, v.estimated_cost
FROM (
    VALUES
        ('Sala', 'Muro divisorio entre sala y comedor', 'structure', 'Demoler el muro divisorio', 'Muro no portante. Apuntalar el dintel antes de demoler.', 'planned', '2026-11-02', '2026-11-06', 950),
        ('Hab. principal', 'Ducto de aire acondicionado', 'installations', 'Instalar el ducto de aire acondicionado', 'Ducto rectangular bajo la losa, con rejilla sobre la cabecera.', 'planned', '2026-11-09', '2026-11-13', 1800),
        ('Hab. principal', 'Piso de madera de la habitación principal', 'finishes', 'Colocar el piso de madera', 'Duela de chanul sobre la losa nivelada.', 'planned', '2026-11-16', '2026-11-20', 2400),
        ('Baño principal', 'Desagüe nuevo de la ducha', 'installations', 'Cambiar el desagüe de la ducha', 'Tubería de PVC de 75 mm con pendiente del 2 por ciento.', 'in_progress', '2026-10-05', '2026-10-09', 420),
        ('Baño principal', 'Enchape de porcelanato', 'finishes', 'Enchapar la pared húmeda', 'Porcelanato de 60 × 120 cm hasta 2,20 m de altura.', 'planned', '2026-10-12', '2026-10-16', 1150)
) AS v (room, element, layer, title, description, status, planned_start, planned_end, estimated_cost)
JOIN projects p ON p.name = 'Casa Los Arrayanes'
JOIN users u ON u.id = p.owner_id AND u.email = 'demo@example.com'
JOIN rooms r ON r.project_id = p.id AND r.name = v.room
LEFT JOIN spatial_elements e ON e.project_id = p.id AND e.name = v.element
WHERE NOT EXISTS (
    SELECT 1 FROM renovation_logs x WHERE x.project_id = p.id AND x.title = v.title
);
