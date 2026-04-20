import math

from flask_restful import Resource, reqparse
from authentication_manager import get_database_connection
from car_park_manager import CarParkSchema

def to_float(value):
        try:
            return float(value)
        except (TypeError, ValueError):
            return None


def extract_distance(car_park, origin_lon, origin_lat):
        direct_distance = to_float(car_park.get("distance"))
        if direct_distance is not None:
            return direct_distance

        car_park_lon = to_float(
            car_park.get("longitude", car_park.get("lon"))
        )
        car_park_lat = to_float(
            car_park.get("latitude", car_park.get("lattitude", car_park.get("lat")))
        )

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
        parser.add_argument("minPrice", type=float, required=True, location="args")
        parser.add_argument("maxPrice", type=float, required=True, location="args")
        parser.add_argument("minRating", type=float, required=True, location="args")
        parser.add_argument("maxRating", type=float, required=True, location="args")
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

        if args["minPrice"] > args["maxPrice"]:
            return {"error": "minPrice cannot be greater than maxPrice"}, 400
        if args["minRating"] > args["maxRating"]:
            return {"error": "minRating cannot be greater than maxRating"}, 400
        if args["minDistance"] > args["maxDistance"]:
            return {"error": "minDistance cannot be greater than maxDistance"}, 400

        query = args["query"].strip().lower()
        min_price = args["minPrice"]
        max_price = args["maxPrice"]
        min_rating = args["minRating"]
        max_rating = args["maxRating"]
        min_distance = args["minDistance"]
        max_distance = args["maxDistance"]
        user_longitude = args["longitude"]

        supabase = get_database_connection()
        response = supabase.table("car_parks").select("*").execute()

        if getattr(response, "error", None):
            return {"error": "Failed to fetch car parks"}, 500

        filtered_results = []
        for car_park in response.data or []:
            name = (car_park.get("name") or "").strip()
            if query and query not in name.lower():
                continue

            price = to_float(car_park.get("price"))
            rating = to_float(car_park.get("avg_rating", car_park.get("rating")))
            distance = extract_distance(
                car_park=car_park,
                origin_lon=user_longitude,
                origin_lat=user_latitude,
            )

            if not within_range(price, min_price, max_price):
                continue
            if not within_range(rating, min_rating, max_rating):
                continue
            if not within_range(distance, min_distance, max_distance):
                continue

            car_park["distance"] = distance
            filtered_results.append(car_park)

        return CarParkSchema(many=True).dump(filtered_results), 200
