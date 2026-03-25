INSERT INTO users (id, username, email, password_hash, role, created_at, updated_at)
VALUES 
    (1, 'admin', 'admin@parkingapp.com', 'Setap_admin', 'admin', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    (2, 'superadmin', 'superadmin@parkingapp.com', 'Setap_superadmin', 'admin', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

-- Mock data for schema.sql -> CarParkType + CarPark
INSERT INTO CarParkType (type_label)
VALUES ('Public Multi-Storey');

INSERT INTO CarPark (name, location, is_restricted, type_id, space_type)
VALUES (
    'Central City Car Park',
    ST_SetSRID(ST_MakePoint(-0.1278, 51.5074), 4326),
    FALSE,
    (SELECT type_id FROM CarParkType WHERE type_label = 'Public Multi-Storey' LIMIT 1),
    'CAR'
);


 