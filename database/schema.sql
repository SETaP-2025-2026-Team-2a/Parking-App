


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