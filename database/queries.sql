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