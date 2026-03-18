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

-- Find nearby car parks by point and radius (meters)
SELECT
  cp.carpark_id,
  cp.name,
  ST_Distance(
    cp.location::geography,
    ST_SetSRID(ST_MakePoint($1, $2), 4326)::geography
  ) AS distance_meters
FROM CarPark cp
WHERE ST_DWithin(
  cp.location::geography,
  ST_SetSRID(ST_MakePoint($1, $2), 4326)::geography,
  $3
)
ORDER BY distance_meters
LIMIT $4 OFFSET $5;



-- Start parking session
INSERT INTO ParkingSession (start_time, expiry_time, user_id, vehicle_id, carpark_id)
VALUES (NOW(), $1, $2, $3, $4)
RETURNING session_id;

