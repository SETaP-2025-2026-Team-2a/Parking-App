--CREATE A USER

INSERT INTO "User" (first_name, last_name, email, password_hash)
VALUES ($1, $2, $3, $4)
RETURNING user_id;

-- LOGIN LOOKUP + GET USER PROFILE

SELECT user_id, email, password_hash
FROM "User"
WHERE email = $1;

-- ADD A VEHICLE
INSERT INTO Vehicle (user_id, registration, type)
VALUES ($1, $2, $3)
RETURNING vehicle_id;

-- List user vehicles
SELECT vehicle_id, registration, type
FROM Vehicle
WHERE user_id = $1
ORDER BY vehicle_id DESC;

--DELETE A VEHICLE

DELETE FROM Vehicle
WHERE vehicle_id = $1 AND user_id = $2;


-- Create car park
INSERT INTO CarPark (name, location, is_restricted, type_id, space_type)
VALUES (
  $1,
  ST_SetSRID(ST_MakePoint($2, $3), 4326),
  $4,
  $5,
  $6
)
RETURNING carpark_id;