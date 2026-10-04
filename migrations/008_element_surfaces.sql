ALTER TABLE rooms ADD COLUMN surface VARCHAR(20)
    CHECK (surface IN ('concrete', 'brick', 'plaster', 'glass', 'steel', 'wood', 'stone'));

ALTER TABLE structural_components ADD COLUMN surface VARCHAR(20)
    CHECK (surface IN ('concrete', 'brick', 'plaster', 'glass', 'steel', 'wood', 'stone'));

ALTER TABLE plans ADD COLUMN surface VARCHAR(20)
    CHECK (surface IN ('concrete', 'brick', 'plaster', 'glass', 'steel', 'wood', 'stone'));
