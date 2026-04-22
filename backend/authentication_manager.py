from flask_restful import Resource, reqparse
from werkzeug.security import check_password_hash, generate_password_hash
import os
from datetime import datetime, timedelta, timezone
import jwt
from dotenv import load_dotenv
from supabase import create_client, Client


load_dotenv()  # Load environment variables from .env file

JWT_SECRET = os.getenv("JWT_SECRET")
JWT_ALGORITHM = os.getenv("JWT_ALGORITHM")
JWT_EXPIRES_MINUTES = int(os.getenv("JWT_EXPIRES_MINUTES", "60"))  # Default to 60 minutes if not set

SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_ANON_KEY = os.getenv("SUPABASE_ANON_KEY")   


def create_session_token(user):
    now = datetime.now(timezone.utc)
    payload = {
        "sub": f"{user['email']}",
        "name": user["first_name"],
        "lastname": user["last_name"],
        "iat": int(now.timestamp()),
        "exp": int((now + timedelta(minutes=JWT_EXPIRES_MINUTES)).timestamp()),
    }
    return jwt.encode(payload, JWT_SECRET, algorithm=JWT_ALGORITHM)

def get_database_connection():
    supabase: Client = create_client(SUPABASE_URL, SUPABASE_ANON_KEY)
    return supabase

def getUser(email=None):
    try:
        supabase = get_database_connection()
        response = supabase.table("User").select("*").eq("email", email).execute()
        if response.error:
            print(f"Error fetching user from database: {response.error.message}")
            return {
                "email": email,
                "result": False,
                "error": "An error occurred while fetching the user"
            }
        if response.data:
            return {
                "name": response.data[0]["name"],
                "lastname": response.data[0]["lastname"],
                "email": response.data[0]["email"],
                "password_hash": response.data[0]["password_hash"],
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


def createUserAccount(name, lastname, email, password):
    try:
        existing_user = getUser(email=email)
        if existing_user and existing_user.get("result") is True:
            return {
                "process": "Sign Up",
                "result": False,
                "error": "Email already exists",
            }, 409

        password_hash = generate_password_hash(password)
        supabase = get_database_connection()
        response = (
            supabase.table("User")
            .insert(
                {
                    "first_name": name,
                    "last_name": lastname,
                    "email": email,
                    "password_hash": password_hash,
                }
            )
            .execute()
        )

        if getattr(response, "error", None):
            return {
                "process": "Sign Up",
                "result": False,
                "error": "Failed to create account",
            }, 500

        return {
            "process": "Sign Up",
            "result": True,
            "name": name,
            "lastname": lastname,
            "email": email,
        }, 201
    except Exception as e:
        print(f"Error occurred during sign up: {e}")
        return {
            "process": "Sign Up",
            "result": False,
            "error": "An error occurred during sign up",
        }, 500


def deleteUser(email, password):
    try:
        user = getUser(email=email)
        if not user or user.get("result") is False:
            return {"process": "Delete User", "error": "Invalid credentials"}, 401
        if not check_password_hash(user["password_hash"], password):
            return {"process": "Delete User", "result": False, "error": "Invalid credentials"}, 401

        print(f"Deleting user: {user['name']}")

        supabase = get_database_connection()
        response = supabase.table("User").delete().eq("email", email).execute()
        if response.error:
            print(f"Error deleting user from database: {response.error.message}")
            return {"process": "Delete User", "error": "An error occurred while deleting the user"}, 500

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


class SignupResource(Resource):
    def post(self):
        parser = reqparse.RequestParser()
        parser.add_argument("name", type=str, required=True)
        parser.add_argument("lastname", type=str, required=False, default="")
        parser.add_argument("email", type=str, required=True)
        parser.add_argument("password", type=str, required=True)
        args = parser.parse_args()

        return createUserAccount(
            args["name"],
            args["lastname"],
            args["email"],
            args["password"],
        )