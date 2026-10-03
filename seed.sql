INSERT INTO users (name, email)
VALUES
    ('Demo User', 'demo@example.com')
ON CONFLICT (email) DO NOTHING;

INSERT INTO projects (owner_id, name, description, location, status)
SELECT id, 'Demo House', 'Two-storey single-family house', 'Quito, Ecuador', 'active'
FROM users
WHERE email = 'demo@example.com'
ON CONFLICT (owner_id, name) DO NOTHING;

INSERT INTO terrains (project_id, name, area_m2, width_m, length_m, slope_percent, soil_type, latitude, longitude)
SELECT p.id, 'Main Lot', 450.00, 15.00, 30.00, 8.50, 'clay', -0.180653, -78.467834
FROM projects p
WHERE p.name = 'Demo House'
  AND NOT EXISTS (
      SELECT 1 FROM terrains t WHERE t.project_id = p.id AND t.name = 'Main Lot'
  );

INSERT INTO materials (project_id, name, category, unit, quantity, unit_cost)
SELECT p.id, m.name, m.category, m.unit, m.quantity, m.unit_cost
FROM projects p
CROSS JOIN (
    VALUES
        ('Concrete 210 kg/cm2', 'structure', 'm3', 85.00, 110.00),
        ('Steel rebar 12 mm', 'structure', 'kg', 4200.00, 1.35),
        ('Clay brick', 'masonry', 'unit', 12000.00, 0.28)
) AS m (name, category, unit, quantity, unit_cost)
WHERE p.name = 'Demo House'
ON CONFLICT (project_id, name) DO NOTHING;
