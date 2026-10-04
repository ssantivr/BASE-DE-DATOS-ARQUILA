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
