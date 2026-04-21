from flask_restful import Resource, reqparse
from marshmallow import Schema, fields
from datetime import datetime, timedelta

from user_manager import get_database_connection


class ParkingSessionSchema(Schema):
    user_id = fields.Integer(required=True)
    carpark_id = fields.Integer(required=True)
    user_rating = fields.Integer()

    start_time = fields.Integer(required=True)
    end_time = fields.Integer(required=True)
    expiry_time = fields.Integer(required=True)


class ParkingSessionManager(Resource):
    # Get the session(s) associated with a user
    def get(self, **kwargs):
        try:

            parser = reqparse.RequestParser()
            parser.add_argument("user_id", type=int, required=True)
            args = parser.parse_args()

            supabase = get_database_connection()
            response = (
                supabase.table("ParkingSession")
                .select("*")
                .eq("user_id", args["user_id"])
                .execute()
            )

            if response.data:
                return {
                    "data": [
                        ParkingSessionSchema().dump(session)
                        for session in response.data
                    ]
                }, 200

        except Exception as e:
            return {"error": e}, 500

    def post(self):
        parser = reqparse.RequestParser()
        parser.add_argument("user_id", type=int, required=True)
        parser.add_argument("vehicle_id", type=int, required=True)
        parser.add_argument("carpark_id", type=int, required=True)
        parser.add_argument("duration", type=int, required=True)
        args = parser.parse_args()

        # Perform extra validation
        if args["start_time"] > args["end_time"]:
            return {"error": "Start time must be greater than end time"}, 400
        elif args["start_time"] < 0 or args["end_time"] < 0:
            return {"error": "Times must be positive"}

        # Check if user, carpark, and vehicle exist
        # TODO extra validation to link user to vehicle

        supabase = get_database_connection()

        try:
            response = (
                supabase.table("User")
                .select("user_id")
                .eq("user_id", args["user_id"])
                .execute()
            )
            if len(response.data) != 1:
                raise Exception("No user with ID")

            response = (
                supabase.table("UserVehicles")
                .select("vehicle_id")
                .eq("vehicle_id", args["vehicle_id"])
                .execute()
            )
            if len(response.data) != 1:
                raise Exception("No vehicle with ID")

            response = (
                supabase.table("CarPark")
                .select("carpark_id")
                .eq("carpark_id", args["carpark_id"])
                .execute()
            )
            if len(response.data) != 1:
                raise Exception("No carpark with ID")

        except Exception as e:
            return {"error": e}

        # Otherwise create new parking session
        try:
            response = supabase.table("ParkingSession").insert(
                {
                    "user_id": args["user_id"],
                    "vehicle_id": args["vehicle_id"],
                    "carpark_id": args["carpark_id"],
                    "start_time": datetime.now().isoformat(),
                    "end_time": datetime.now() + timedelta(seconds=args["duration"]),
                    "expiry_time": datetime.now() + timedelta(seconds=args["duration"]),
                }
            )

        except Exception as e:
            return {"error": e}, 500

    def put(self):
        VALID_ACTIONS = ["extend", "cancel"]

        parser = reqparse.RequestParser()
        parser.add_argument("user_id", required=True, type=int)
        parser.add_argument("session_id", required=True, type=int)
        parser.add_argument("action", required=True, type=str)
        parser.add_argument("action_data", type=str)
        args = parser.parse_args()

        if not args["action"] in VALID_ACTIONS:
            return {"error": "Inalid action"}, 400

        supabase = get_database_connection()

        try:
            response = (
                supabase.table("User")
                .select("user_id")
                .eq("user_id", args["user_id"])
                .execute()
            )
            if len(response.data) != 1:
                raise Exception("No user with ID")

            response = (
                supabase.table("ParkingSession")
                .select("session_id")
                .eq("session_id", args["session_id"])
                .execute()
            )
            if len(response.data) != 1:
                raise Exception("No session with ID")

        except Exception as e:
            return {"error": e}
        
        if args["action"] == "cancel":
            # TODO: Unsure whether to delete or mark as invalid
            pass
        elif args["action"] == "extend":
            try:
                # Firstly get current duration
                response = supabase.table("ParkingSession").select("expiry_time").eq("session_id", args["session_id"]).execute()
                expiry_time = datetime.fromisoformat(response.data[0]["expiry_time"])

                response = supabase.table("ParkingSession").update({
                    "end_time": expiry_time + timedelta(seconds=int(args["action_data"]))
                }).execute()
            except Exception as e:
                return {"error": e}, 500
            