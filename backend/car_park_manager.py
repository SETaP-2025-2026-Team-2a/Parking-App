from flask_restful import Resource, reqparse
from marshmallow import Schema, fields, validate


class CarParkSchema(Schema):
    carpark_id = fields.String()
    name = fields.String()
    spaces = fields.Integer(validate=validate.Range(min=0))
    distance = fields.Float(validate=validate.Range(min=0))
    avg_rating = fields.Float(validate=validate.Range(min=0))


class CarPark(Resource):
    def get(self):
        parser = reqparse.RequestParser()
        parser.add_argument("carpark_id", type=int, required=True)

        # TODO
        # verify car park exists
        # execute query
        # return car park

        return {
            "data": CarParkSchema(
                {
                    "carpark_id": 0,
                    "name": "Gunwharf Quays",
                    "price": 100,
                    "distance": 10,
                    "avg_rating": 1.0,
                }
            ).dump()
        }
