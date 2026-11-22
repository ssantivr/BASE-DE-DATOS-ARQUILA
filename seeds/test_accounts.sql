-- Test accounts, one per role (R02). Load them with scripts/seed_demo_50.sh only.
-- Only Argon2id hashes are here. The passwords are in docs/TEST_ACCOUNTS.md.
-- One statement: without the mark nothing in this file runs, whatever the psql options.
DO $seed$
BEGIN
    IF current_setting('arquila.environment', true) IS DISTINCT FROM 'local' THEN
        RAISE EXCEPTION 'Refused: test data needs a database marked as local';
    END IF;

INSERT INTO users (name, email, password_hash)
VALUES
    ('Administración de prueba', 'admin@example.com', '$argon2id$v=19$m=65536,t=4,p=4$9o3hU2ttAcmXNYVa5xCiGg$SWtyK/MKQYfEpvdKFTyMFV/hcK5diYK3IJ8p840tx6A'),
    ('Arquitectura de prueba', 'architect@example.com', '$argon2id$v=19$m=65536,t=4,p=4$4Rgpc6Vghf6PyqzYcrTltw$K5eR2wJe2WPX2YCNHm8pY9FdKNid4fz3MbwiB/wxSho'),
    ('Consulta de prueba', 'viewer@example.com', '$argon2id$v=19$m=65536,t=4,p=4$Wck3U2kFMjn2mIpueawIDw$QbB9sZETJ/faJK8FzBIJ49UkA93H8BDq0/007EZ6uvc')
ON CONFLICT (email) DO UPDATE SET password_hash = EXCLUDED.password_hash;

-- One role each, whatever the account had before.
DELETE FROM user_roles
WHERE user_id IN (
    SELECT id FROM users
    WHERE email IN ('admin@example.com', 'architect@example.com', 'viewer@example.com')
);

INSERT INTO user_roles (user_id, role_id)
SELECT u.id, r.id
FROM (
    VALUES
        ('admin@example.com', 'admin'),
        ('architect@example.com', 'architect'),
        ('viewer@example.com', 'viewer')
) AS v (email, role)
JOIN users u ON u.email = v.email
JOIN roles r ON r.name = v.role
ON CONFLICT DO NOTHING;
END
$seed$;
