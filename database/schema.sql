


CREATE TABLE CarPark (
    carpark_id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    lATITUDE DECIMAL(10, 6) NOT NULL,
    LONGITUDE DECIMAL(10, 6) NOT NULL,
    is_restricted BOOLEAN NOT NULL,
    type_id INT,
    space_type ENUM('CAR', 'MOTORCYCLE', 'LORRY', 'DISABLED', "PARENT AND CHILD"),
    FOREIGN KEY (type_id) REFERENCES CarParkType(type_id)
)

CREATE TABLE CarParkType (
    type_id SERIAL PRIMARY KEY,
    type_label VARCHAR(50) NOT NULL
)

CREATE TABLE ParkingSpace (
    space_id SERIAL PRIMARY KEY,
    carpark_id INT NOT NULL,
    is_occupied BOOLEAN NOT NULL,
    FOREIGN KEY (carpark_id) REFERENCES CarPark(carpark_id),
    FOREIGN KEY (space_type) REFERENCES CarPark(space_type)
)