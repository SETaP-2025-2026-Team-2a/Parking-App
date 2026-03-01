from flask_restful import Resource
from flask import request
from marshmallow import Schema, fields, ValidationError, validate

class CreateReviewSchema(Schema):
    user_id = fields.String(required=True)

    title = fields.String(validate=validate.Length(min=1, max=32))
    body = fields.String(validate=validate.Length(min=1, max=500))
    rating = fields.Integer(strict=True, validate=validate.Range(min=0, max=5), required=True)

class DeleteReviewSchema(Schema):
    review_id = fields.String(required=True)

class GetReviewsSchema(Schema):
    car_park_id = fields.String(required=True)

class ReviewManager(Resource):
    def get(self, **kwargs):
        schema = GetReviewsSchema()

        try:
            data = schema.load(request.get_json())
        except ValidationError as err:
            return {"error": err.messages}, 400

    def post():
        schema = CreateReviewSchema()

        try:
            data = schema.load(request.get_json())
        except ValidationError as err:
            return {"error": err.messages}, 400

    def delete():
        schema = DeleteReviewSchema()

        try:
            data = schema.load(request.get_json())
        except ValidationError as err:
            return {"error": err.messages}, 400