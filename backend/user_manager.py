from flask_restful import Resource, reqparse
from modules import get_database_connection
from authentication_manager import getUser as auth_getUser

    


def get_user(email):
    try:
        user = auth_getUser(email=email)
        if user and user.get("result") is True:
            supabase = get_database_connection()
            vehicle_response = (
                supabase.table("Vehicle")
                .select("vehicle_id, registration, type")
                .eq("user_id", user.get("user_id"))
                .order("vehicle_id", desc=False)
                .execute()
            )
            vehicles = vehicle_response.data if vehicle_response and vehicle_response.data else []

            return {
                "process": "Get User",
                "user_id": user.get("user_id"),
                "name": user.get("first_name") or user.get("name"),
                "lastname": user.get("last_name") or user.get("lastname"),
                "email": user.get("email"),
                "vehicles": vehicles,
                "result": True,
            }, 200

        return {
            "process": "Get User",
            "user_id": None,
            "name": None,
            "lastname": None,
            "email": email,
            "vehicles": [],
            "error": "User not found",
            "result": False,
        }, 404
    except Exception as e:
        print(f"Error occurred while fetching user: {e}")
        return {
            "process": "Get User",
            "user_id": None,
            "name": None,
            "lastname": None,
            "email": email, 
            "vehicles": [],
            "error": "User not found",
            "result": False
        }, 404



def update_user(name, lastname, email=None):
    supabase = get_database_connection()
    response = (
        supabase.table("User")
        .update({"first_name": name, "last_name": lastname})
        .eq("email", email)
        .execute()
    )
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



class UserResource(Resource):
    def get(self, email):
        return get_user(email)

    def put(self, email):
        parser = reqparse.RequestParser()
        parser.add_argument("name", type=str, required=True)
        parser.add_argument("lastname", type=str, required=True)
        args = parser.parse_args()

        return update_user(args["name"], args["lastname"], email)



