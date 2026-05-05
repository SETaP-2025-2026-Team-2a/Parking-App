
CREATE EXTENSION IF NOT EXISTS postgis;

CREATE TYPE carpark_space_type_enum AS ENUM (
    'CAR',
    'MOTORCYCLE',
    'LORRY',
    'DISABLED',
    'PARENT_AND_CHILD'
);

CREATE TYPE vehicle_type_enum AS ENUM (
    'CAR',
    'MOTORCYCLE',
    'LORRY',
    'EV',
    'PCV'
);

CREATE TABLE CarParkType (
    type_id SERIAL PRIMARY KEY,
    type_label VARCHAR(50) NOT NULL
);

CREATE TABLE CarPark (
    carpark_id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    location GEOMETRY(POINT, 4326),
    is_restricted BOOLEAN NOT NULL,
    type_id INT,
    space_type carpark_space_type_enum,
    FOREIGN KEY (type_id) REFERENCES CarParkType(type_id)
);

CREATE INDEX idx_carpark_location ON CarPark USING GIST(location);

CREATE TABLE ParkingSpace (
    space_id SERIAL PRIMARY KEY,
    carpark_id INT NOT NULL,
    space_type carpark_space_type_enum,
    is_occupied BOOLEAN NOT NULL,
    FOREIGN KEY (carpark_id) REFERENCES CarPark(carpark_id)
);

CREATE TABLE "User" (
    user_id SERIAL PRIMARY KEY,
    payment_token VARCHAR(255) NOT NULL,
    first_name VARCHAR(255) NOT NULL,
    last_name VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL
);

CREATE TABLE Vehicle (
    vehicle_id SERIAL PRIMARY KEY,
    user_id INT NOT NULL,
    registration VARCHAR(20) NOT NULL UNIQUE,
    type vehicle_type_enum,
    FOREIGN KEY (user_id) REFERENCES "User"(user_id)
);

CREATE TABLE ParkingSession (
    session_id SERIAL PRIMARY KEY,
    user_id INT NOT NULL,
    vehicle_id INT NOT NULL,
    carpark_id INT NOT NULL,
    user_rating INT,
    start_time TIMESTAMP NOT NULL,
    end_time TIMESTAMP NOT NULL,
    expiry_time TIMESTAMP NOT NULL,
    FOREIGN KEY (user_id) REFERENCES "User"(user_id),
    FOREIGN KEY (vehicle_id) REFERENCES Vehicle(vehicle_id),
    FOREIGN KEY (carpark_id) REFERENCES CarPark(carpark_id)
);

CREATE TABLE UserVehicles (
    user_id INT NOT NULL,
    vehicle_id INT NOT NULL,
    PRIMARY KEY (user_id, vehicle_id),
    FOREIGN KEY (user_id) REFERENCES "User"(user_id),
    FOREIGN KEY (vehicle_id) REFERENCES Vehicle(vehicle_id)
);

CREATE TABLE Reviews (
    review_id SERIAL PRIMARY KEY,
    title TEXT NOT NULL,
    review INT NOT NULL CHECK (review >= 0 AND review <= 5),
    comment TEXT NOT NULL,
    user_email VARCHAR(255) NOT NULL,
    user_name VARCHAR(255) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- =====================================================
-- PostGIS Location Services - Useful Queries
-- =====================================================
-- Note: Populate the location column using:
-- UPDATE CarPark SET location = ST_SetSRID(ST_MakePoint(longitude, latitude), 4326) WHERE location IS NULL;

-- Find nearest parking spots within 5km of a point (latitude, longitude):
-- SELECT carpark_id, name, 
--        ST_Distance(location::geography, ST_SetSRID(ST_MakePoint(:longitude, :latitude), 4326)::geography) as distance_meters
-- FROM CarPark
-- WHERE ST_DWithin(location::geography, ST_SetSRID(ST_MakePoint(:longitude, :latitude), 4326)::geography, 5000)
-- ORDER BY distance_meters LIMIT 20;

-- Find car parks within a specific radius (e.g., 1km):
-- SELECT carpark_id, name FROM CarPark 
-- WHERE ST_Distance(location, ST_SetSRID(ST_MakePoint(:user_lon, :user_lat), 4326)) < 1000;