--CREATE A USER

INSERT INTO "User" (first_name, last_name, email, password_hash)
VALUES ('John', 'Doe', 'john.doe@example.com', 'hashed_password')
RETURNING user_id;

