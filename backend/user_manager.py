import json

from flask import request
from flask_restful import Resource
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
            payment_methods = []

            payment_token = user.get("payment_token")
            if payment_token:
                try:
                    parsed = json.loads(payment_token)
                    if isinstance(parsed, list):
                        payment_methods = parsed
                except Exception:
                    payment_methods = []

            return {
                "process": "Get User",
                "user_id": user.get("user_id"),
                "name": user.get("first_name") or user.get("name"),
                "lastname": user.get("last_name") or user.get("lastname"),
                "email": user.get("email"),
                "vehicles": vehicles,
                "payment_methods": payment_methods,
                "result": True,
            }, 200

        return {
            "process": "Get User",
            "user_id": None,
            "name": None,
            "lastname": None,
            "email": email,
            "vehicles": [],
            "payment_methods": [],
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
            "payment_methods": [],
            "error": "User not found",
            "result": False
        }, 404


def _normalise_vehicle_type(raw_type):
    if not raw_type:
        return "CAR"

    normalised = str(raw_type).upper().strip()
    allowed = {"CAR", "MOTORCYCLE", "LORRY", "EV", "PCV"}
    if normalised in allowed:
        return normalised

    aliases = {
        "PERSONAL": "CAR",
        "WORK": "PCV",
        "FAMILY": "CAR",
        "OTHER": "CAR",
    }
    return aliases.get(normalised, "CAR")


def update_user(name, lastname, email=None, updated_email=None, vehicles=None, payment_methods=None):
    supabase = get_database_connection()

    payment_methods = payment_methods or []
    vehicles = vehicles or []

    update_payload = {
        "first_name": name,
        "last_name": lastname,
        "payment_token": json.dumps(payment_methods),
    }
    if updated_email and updated_email != email:
        update_payload["email"] = updated_email

    response = (
        supabase.table("User")
        .update(update_payload)
        .eq("email", email)
        .execute()
    )

    if response.data:
        user_id = response.data[0].get("user_id")

        supabase.table("Vehicle").delete().eq("user_id", user_id).execute()

        for vehicle in vehicles:
            registration = (vehicle.get("vrm") or vehicle.get("registration") or "").strip().upper()
            if not registration:
                continue

            vehicle_type = _normalise_vehicle_type(vehicle.get("type"))
            supabase.table("Vehicle").insert(
                {
                    "user_id": user_id,
                    "registration": registration,
                    "type": vehicle_type,
                }
            ).execute()

        print(f"Updating user: {name} {lastname}, email: {email}")
        return {
            "process": "Update User",
            "email": updated_email or email,
            "result": True,
        }, 200

    return {
        "process": "Update User",
        "result": False
    }, 404



class UserResource(Resource):
    def get(self, email):
        return get_user(email)

    def put(self, email):
        body = request.get_json(silent=True) or {}

        name = body.get("name")
        lastname = body.get("lastname")

        if name is None or lastname is None:
            return {
                "process": "Update User",
                "result": False,
                "error": "name and lastname are required",
            }, 400

        return update_user(
            name=name,
            lastname=lastname,
            email=email,
            updated_email=body.get("email"),
            vehicles=body.get("vehicles", []),
            payment_methods=body.get("payment_methods", []),
        )



