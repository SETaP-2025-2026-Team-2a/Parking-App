from flask_restful import Resource, reqparse
from marshmallow import Schema, fields, validate

from modules import get_database_connection


class CarParkSchema(Schema):
    carpark_id = fields.String()
    name = fields.String()
    spaces = fields.Integer(validate=validate.Range(min=0))
    price = fields.Float(validate=validate.Range(min=0), allow_none=True)
    distance = fields.Float(validate=validate.Range(min=0))
    avg_rating = fields.Float(validate=validate.Range(min=0))


class CarPark(Resource):
    def get(self):
        parser = reqparse.RequestParser()
        parser.add_argument("carpark_id", type=int, required=True)
        args = parser.parse_args()
        
        supabase = get_database_connection()
        response = supabase.table("car_parks").select("name", "spaces", "distance", "avg_rating").eq("carpark_id", args["carpark_id"]).execute()
        if response.data:
            car_park_data = response.data[0]
            return {
                "data": CarParkSchema().dump(car_park_data)
            }, 200
        return {
            "error": "Car park not found"
        }, 404

    def post(self):
        parser = reqparse.RequestParser()
        parser.add_argument("name", type=str, required=True)
        parser.add_argument("spaces", type=int, required=True)
        parser.add_argument("distance", type=float, required=True)
        parser.add_argument("avg_rating", type=float, required=True)
        args = parser.parse_args()

        supabase = get_database_connection()
        response = supabase.table("car_parks").insert({
            "name": args["name"],
            "spaces": args["spaces"],
            "distance": args["distance"],
            "avg_rating": args["avg_rating"]
        }).execute()

        if response.error:
            return {
                "error": "Failed to create car park"
            }, 500

        return {
            "data": CarParkSchema().dump(response.data[0])
        }, 201