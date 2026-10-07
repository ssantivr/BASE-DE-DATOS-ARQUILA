CREATE TABLE IF NOT EXISTS roles (
    id SERIAL PRIMARY KEY,
    name VARCHAR(40) UNIQUE NOT NULL,
    description VARCHAR(255) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS permissions (
    id SERIAL PRIMARY KEY,
    code VARCHAR(80) UNIQUE NOT NULL,
    description VARCHAR(255) NOT NULL
);

CREATE TABLE IF NOT EXISTS role_permissions (
    role_id INTEGER NOT NULL REFERENCES roles (id) ON DELETE CASCADE,
    permission_id INTEGER NOT NULL REFERENCES permissions (id) ON DELETE CASCADE,
    PRIMARY KEY (role_id, permission_id)
);

CREATE TABLE IF NOT EXISTS user_roles (
    user_id INTEGER NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    role_id INTEGER NOT NULL REFERENCES roles (id) ON DELETE CASCADE,
    assigned_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id, role_id)
);

CREATE INDEX IF NOT EXISTS idx_role_permissions_permission_id ON role_permissions (permission_id);
CREATE INDEX IF NOT EXISTS idx_user_roles_role_id ON user_roles (role_id);

INSERT INTO roles (name, description)
VALUES
    ('admin', 'Full access, including assigning roles to users'),
    ('architect', 'Reads and edits units, rooms, spatial data and walkthroughs'),
    ('viewer', 'Reads units, rooms, spatial data and walkthroughs')
ON CONFLICT (name) DO NOTHING;

INSERT INTO permissions (code, description)
VALUES
    ('units:read', 'Read properties and units'),
    ('units:write', 'Create, edit and delete properties and units'),
    ('rooms:read', 'Read rooms and their spatial metadata'),
    ('rooms:write', 'Edit the spatial metadata of rooms'),
    ('spatial:read', 'Read spatial elements and 3D asset configuration'),
    ('spatial:write', 'Create, import, edit and delete spatial elements'),
    ('walkthrough:read', 'Read walkthrough steps and renovation logs'),
    ('walkthrough:write', 'Create, edit and delete walkthrough steps and renovation logs'),
    ('roles:manage', 'Assign roles to users')
ON CONFLICT (code) DO NOTHING;

INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r
JOIN permissions p
    ON r.name = 'admin'
    OR (r.name = 'architect' AND p.code <> 'roles:manage')
    OR (r.name = 'viewer' AND right(p.code, 5) = ':read')
ON CONFLICT DO NOTHING;

INSERT INTO user_roles (user_id, role_id)
SELECT u.id, r.id
FROM users u
CROSS JOIN roles r
WHERE r.name = 'architect'
ON CONFLICT DO NOTHING;
