from flask_restful import Resource, reqparse
from car_park_manager import CarParkSchema


class SearchManager(Resource):
    def get(self, **kwargs):
        parser = reqparse.RequestParser()
        parser.add_argument("query", type=str, required=True)
        parser.add_argument("minPrice", type=float, required=True)
        parser.add_argument("maxPrice", type=float, required=True)
        parser.add_argument("minRating", type=float, required=True)
        parser.add_argument("maxRating", type=float, required=True)
        parser.add_argument("minDistance", type=float, required=True)
        parser.add_argument("maxDistance", type=float, required=True)
        parser.add_argument("longitude", type=float, required=True)
        parser.add_argument("lattitude", type=float, required=True)
        args = parser.parse_args()

        # TODO: something with the query data
        # location = data["location"]
        # some kind of SQL query etc...

        return [
            CarParkSchema(
                {
                    "name": "Gunwharf Quays",
                    "price": 100,
                    "distance": 10,
                }
            ).dump(),
            CarParkSchema(
                {
                    "name": "The Hard",
                    "price": 100,
                    "distance": 10,
                }
            ).dump(),
            CarParkSchema(
                {
                    "name": "Clarence Esplanade",
                    "price": 100,
                    "distance": 10,
                }
            ).dump(),
        ]
