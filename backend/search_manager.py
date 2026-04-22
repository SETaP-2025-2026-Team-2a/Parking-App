import math

from flask_restful import Resource, reqparse
from modules import get_database_connection
from car_park_manager import CarParkSchema

def to_float(value):
        try:
            return float(value)
        except (TypeError, ValueError):
            return None


def extract_distance(car_park, origin_lon, origin_lat):
        direct_distance = to_float(car_park.get("location"))
        if direct_distance is not None:
            return direct_distance

        location = car_park.get("location", {})
        # need to split coordinates from GeoJSON format (longitude, latitude)
        coordinates = location.get("coordinates", [])
        if len(coordinates) != 2:
            return None
        car_park_lon, car_park_lat = coordinates

        if car_park_lon is None or car_park_lat is None:
            return None

        earth_radius_km = 6371.0
        delta_lat = math.radians(car_park_lat - origin_lat)
        delta_lon = math.radians(car_park_lon - origin_lon)
        start_lat_rad = math.radians(origin_lat)
        end_lat_rad = math.radians(car_park_lat)

        a = (
            math.sin(delta_lat / 2) ** 2
            + math.cos(start_lat_rad)
            * math.cos(end_lat_rad)
            * math.sin(delta_lon / 2) ** 2
        )
        c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
        return earth_radius_km * c


def within_range(value, minimum, maximum):
        return value is not None and minimum <= value <= maximum

class SearchManager(Resource):


    def get(self):
        parser = reqparse.RequestParser()
        parser.add_argument("query", type=str, required=True, location="args")
        parser.add_argument("minDistance", type=float, required=True, location="args")
        parser.add_argument("maxDistance", type=float, required=True, location="args")
        parser.add_argument("longitude", type=float, required=True, location="args")
        parser.add_argument("latitude", type=float, required=False, location="args")
        parser.add_argument("lattitude", type=float, required=False, location="args")
        args = parser.parse_args()

        user_latitude = args.get("latitude")
        if user_latitude is None:
            user_latitude = args.get("lattitude")
        if user_latitude is None:
            return {"error": "Either latitude or lattitude is required"}, 400

        if args["minDistance"] > args["maxDistance"]:
            return {"error": "minDistance cannot be greater than maxDistance"}, 400

        query = args["query"].strip().lower()
        min_distance = args["minDistance"]
        max_distance = args["maxDistance"]
        user_longitude = args["longitude"]

        supabase = get_database_connection()
        response = supabase.table("carpark").select("*").execute()

        if getattr(response, "error", None):
            return {"error": "Failed to fetch car parks"}, 500

        filtered_results = []
        for car_park in response.data or []:
            name = (car_park.get("name") or "").strip()
            if query and query not in name.lower():
                continue

            distance = extract_distance(
                car_park=car_park,
                origin_lon=user_longitude,
                origin_lat=user_latitude,
            )

            if not within_range(distance, min_distance, max_distance):
                continue

            car_park["distance"] = distance
            filtered_results.append(car_park)

        return CarParkSchema(many=True).dump(filtered_results), 200
