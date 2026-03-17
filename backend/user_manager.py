import os
from flask_restful import Resource, reqparse
import psycopg2
from werkzeug.security import generate_password_hash
from dotenv import load_dotenv

load_dotenv()  # Load environment variables from .env file

POSTGRES_USERNAME = os.getenv("POSTGRES_USERNAME")
POSTGRES_PASSWORD = os.getenv("POSTGRES_PASSWORD")
POSTGRES_DB = os.getenv("POSTGRES_DB")
POSTGRES_HOST = os.getenv("POSTGRES_HOST")
POSTGRES_PORT = int(os.getenv("POSTGRES_PORT", "5432"))  # Default to 5432 if not set

def get_database_connection():
    return psycopg2.connect(
        host=POSTGRES_HOST,
        port=POSTGRES_PORT,
        database=POSTGRES_DB,
        user=POSTGRES_USERNAME,
        password=POSTGRES_PASSWORD
    )


def get_user(email):
    with get_database_connection() as conn:
        with conn.cursor() as cursor:
            cursor.execute("SELECT name, lastname FROM users WHERE email = %s", (email,))
            user = cursor.fetchone()
    if user:
        return {
            "process": "Get User",
            "name": user[0],
            "lastname": user[1],
            "result": True
        }
    return {
            "process": "Get User",
            "name": None,
            "lastname": None,
            "email": email, 
            "result": False
        }, 404



def update_user(name, lastname, email=None):
    with get_database_connection() as conn:
        with conn.cursor() as cursor:
                cursor.execute("UPDATE users SET name=%s, lastname=%s WHERE email=%s RETURNING email", (name, lastname, email))
                updated = cursor.fetchone()
    if updated:
        print(f"Updating user: {name} {lastname}, email: {email}")
        return {
            "process": "Update User",
            "result": True
    }
    return {
        "process": "Update User",
        "result": False
    }, 404



def create_user(name, lastname, email, password):
    password_hash = generate_password_hash(password)

    with get_database_connection() as conn:
        with conn.cursor() as cursor:
            cursor.execute(
                """
                INSERT INTO users (name, lastname, email, password_hash)
                VALUES (%s, %s, %s, %s)
                ON CONFLICT (email) DO NOTHING
                RETURNING email
                """,
                (name, lastname, email, password_hash),
            )
            row = cursor.fetchone()

    if not row:
        return {"process": "Create User", "result": False, "error": "Email already exists"}, 409

    return {
        "process": "Create User",
        "result": True,
        "name": name,
        "lastname": lastname,
        "email": row[0],
    }, 201


class UsersResource(Resource):
    def post(self):
        parser = reqparse.RequestParser()
        parser.add_argument("name", type=str, required=True)
        parser.add_argument("lastname", type=str, required=True)
        parser.add_argument("email", type=str, required=True)
        parser.add_argument("password", type=str, required=True)
        args = parser.parse_args()

        return create_user(args["name"], args["lastname"], args["email"], args["password"])

class UserResource(Resource):
    def get(self, email):
        return get_user(email)

    def put(self, email):
        parser = reqparse.RequestParser()
        parser.add_argument("name", type=str, required=True)
        parser.add_argument("lastname", type=str, required=True)
        args = parser.parse_args()

        return update_user(args["name"], args["lastname"], email)



