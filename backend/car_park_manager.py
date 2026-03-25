from flask_restful import Resource
from marshmallow import Schema, fields, validate


class CarParkSchema(Schema):
    name = fields.String()
    spaces = fields.Integer(validate=validate.Range(min=0))
    distance = fields.Float(validate=validate.Range(min=0))


class ParkingSpots(Resource):
    def get(self):
        return {
            "data": [
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
        }
