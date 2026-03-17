from flask_restful import Resource, reqparse
from werkzeug.security import check_password_hash
import os
from datetime import datetime, timedelta, timezone
import jwt
import psycopg2
from dotenv import load_dotenv


load_dotenv()  # Load environment variables from .env file

JWT_SECRET = os.getenv("JWT_SECRET")
JWT_ALGORITHM = os.getenv("JWT_ALGORITHM")
JWT_EXPIRES_MINUTES = int(os.getenv("JWT_EXPIRES_MINUTES", "60"))  # Default to 60 minutes if not set

POSTGRES_USERNAME = os.getenv("POSTGRES_USERNAME")
POSTGRES_PASSWORD = os.getenv("POSTGRES_PASSWORD")
POSTGRES_DB = os.getenv("POSTGRES_DB")
POSTGRES_HOST = os.getenv("POSTGRES_HOST")
POSTGRES_PORT = int(os.getenv("POSTGRES_PORT", "5432"))  # Default to 5432 if not set   


def create_session_token(user):
    now = datetime.now(timezone.utc)
    payload = {
        "sub": f"{user['email']}",
        "name": user["name"],
        "lastname": user["lastname"],
        "iat": int(now.timestamp()),
        "exp": int((now + timedelta(minutes=JWT_EXPIRES_MINUTES)).timestamp()),
    }
    return jwt.encode(payload, JWT_SECRET, algorithm=JWT_ALGORITHM)

def get_database_connection():
    return psycopg2.connect(
        host=POSTGRES_HOST,
        port=POSTGRES_PORT,
        database=POSTGRES_DB,
        user=POSTGRES_USERNAME,
        password=POSTGRES_PASSWORD
    )

def getUser(email=None):
    try:
        with get_database_connection() as conn:
            with conn.cursor() as cursor:
                cursor.execute("SELECT name, lastname, email, password_hash FROM users WHERE email=%s", (email,))
                row = cursor.fetchone()

        if row:
            return {
                "name": row[0],
                "lastname": row[1],
                "email": row[2],
                "password_hash": row[3],
                "result": True
            }
        return {
                "email": email,
                "result": False
            }
    except Exception as e:
        print(f"Error occurred while fetching user: {e}")
        return {
            "email": email,
            "result": False,
            "error": "An error occurred while fetching the user"
        }


def validateUser(email, password):
    try:
        user = getUser(email=email)
        if not user or user.get("result") is False:
            return {"process": "Sign In", "error": "Invalid credentials"}, 401

        if not check_password_hash(user["password_hash"], password):
            return {"process": "Sign In", "result": False, "error": "Invalid credentials"}, 401

        token = create_session_token(user)
        return {
            "process": "Sign In",
            "result": True,
            "name": user["name"],
            "lastname": user["lastname"],
            "access_token": token,
            "token_type": "Bearer",
            "expires_in": JWT_EXPIRES_MINUTES * 60,
        }, 200
    except Exception as e:
        print(f"Error occurred during user validation: {e}")
        return {"process": "Sign In", "error": "An error occurred during authentication"}, 500


def deleteUser(email, password):
    try:
        user = getUser(email=email)
        if not user or user.get("result") is False:
            return {"process": "Delete User", "error": "Invalid credentials"}, 401
        if not check_password_hash(user["password_hash"], password):
            return {"process": "Delete User", "result": False, "error": "Invalid credentials"}, 401

        print(f"Deleting user: {user['name']}")

        with get_database_connection() as conn:
            with conn.cursor() as cursor:
                cursor.execute("DELETE FROM users WHERE email=%s", (email,))
        return {
            "process": "Delete User",
            "name": user["name"],
            "result": True
        }, 200
    except Exception as e:
        print(f"Error occurred while deleting user: {e}")
        return {"process": "Delete User", "error": "An error occurred while deleting the user"}, 500


class LoginResource(Resource):
    def post(self):
        parser = reqparse.RequestParser()
        parser.add_argument("email", type=str, required=True)
        parser.add_argument("password", type=str, required=True)
        args = parser.parse_args()

        # print(args)
        return validateUser(args["email"], args["password"])
    
    def delete(self):
        parser = reqparse.RequestParser()
        parser.add_argument("email", type=str, required=True)
        parser.add_argument("password", type=str, required=True)
        args = parser.parse_args()
        
        return deleteUser(args["email"], args["password"])
