import os
from flask_restful import Resource, reqparse
from supabase import create_client, Client
from werkzeug.security import generate_password_hash
from dotenv import load_dotenv

load_dotenv()  # Load environment variables from .env file

SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_ANON_KEY = os.getenv("SUPABASE_ANON_KEY")

def get_database_connection():
    supabase: Client = create_client(SUPABASE_URL, SUPABASE_ANON_KEY)
    return supabase
    


def get_user(email):
    try:
        supabase = get_database_connection()
        response = supabase.table("users").select("name", "lastname").eq("email", email).execute()
        if response.data:
            return {
                "process": "Get User",
                "name": response.data[0]["name"],
                "lastname": response.data[0]["lastname"],
                "result": True
            }
    except Exception as e:
        print(f"Error occurred while fetching user: {e}")
        return {
            "process": "Get User",
            "name": None,
            "lastname": None,
            "email": email, 
            "error": "User not found",
            "result": False
        }, 404



def update_user(name, lastname, email=None):
    supabase = get_database_connection()
    response = supabase.table("users").update({"name": name, "lastname": lastname}).eq("email", email).execute()
    if response.data:

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
    try:
        supabase = get_database_connection()
        response = supabase.table("person").insert({
            "name": name,
            "lastname": lastname,
            "email": email,
            "password_hash": password_hash
        }).execute()

    except Exception as e:
        print(f"Error occurred while creating user: {e}")
        return {"process": "Create User", "result": False, "error": f"An error occurred: {e}"}, 500

    if response.error:
        return {"process": "Create User", "result": False, "error": "Email already exists"}, 409
    
    return {
        "process": "Create User",
        "result": True,
        "name": name,
        "lastname": lastname,
        "email": response.data[0]["email"],
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



