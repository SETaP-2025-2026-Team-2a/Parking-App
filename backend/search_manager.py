from flask_restful import Resource
from flask import request
from marshmallow import Schema, fields, ValidationError
from enum import Enum

class CarParkTypeEnum(Enum):
    MultiStorey = 1
    Surface = 2
    Underground = 3
    Street = 4

class RangeSchema(Schema):
    min = fields.Float()
    max = fields.Float()

class FiltersSchema(Schema):
    price = fields.Nested(RangeSchema)
    rating = fields.Nested(RangeSchema)
    # In metres
    distance = fields.Nested(RangeSchema)

    types = fields.List(fields.Enum(CarParkTypeEnum))

class LocationSchema(Schema):
    longitude = fields.Float()
    latitude = fields.Float()

class SearchQuerySchema(Schema):
    query = fields.String()

    filters = fields.Nested(FiltersSchema)
    location = fields.Nested(LocationSchema)

class SearchManager(Resource):
    def get(self, **kwargs):
        schema = SearchQuerySchema()

        try:
            data = schema.load(request.get_json())
        except ValidationError as err:
            return {"error": err.messages}, 400
        
        location = data["location"]

        # TODO: something with the query data
