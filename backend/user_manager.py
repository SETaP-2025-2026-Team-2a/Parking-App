from flask_restful import Resource, reqparse
from werkzeug.security import generate_password_hash
from modules import get_database_connection

    


def get_user(email):
    try:
        supabase = get_database_connection()
        response = (
            supabase.table("User")
            .select("first_name", "last_name", "email")
            .eq("email", email)
            .execute()
        )

        if response.data:
            user = response.data[0]
            return {
                "process": "Get User",
                "name": user.get("first_name"),
                "lastname": user.get("last_name"),
                "email": user.get("email"),
                "result": True,
            }, 200

        return {
            "process": "Get User",
            "name": None,
            "lastname": None,
            "email": email,
            "error": "User not found",
            "result": False,
        }, 404
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
    response = supabase.table("User").update({"name": name, "lastname": lastname}).eq("email", email).execute()
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



def create_user(username, email, password):
    password_hash = generate_password_hash(password)
    try:
        supabase = get_database_connection()
        response = supabase.table("User").insert({
            "username": username,  
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
        "username": username,
        "email": response.data[0]["email"],
    }, 201



class UsersResource(Resource):
    def post(self):
        parser = reqparse.RequestParser()
        parser.add_argument("username", type=str, required=True)
        parser.add_argument("email", type=str, required=True)
        parser.add_argument("password", type=str, required=True)
        args = parser.parse_args()

        return create_user(args["username"], args["email"], args["password"])

class UserResource(Resource):
    def get(self, email):
        return get_user(email)

    def put(self, email):
        parser = reqparse.RequestParser()
        parser.add_argument("name", type=str, required=True)
        parser.add_argument("lastname", type=str, required=True)
        args = parser.parse_args()

        return update_user(args["name"], args["lastname"], email)



