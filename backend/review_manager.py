from flask_restful import Resource, reqparse
from flask import request
from marshmallow import Schema, fields, validate

from modules import get_database_connection, get_database_connection_admin

class ReviewSchema(Schema):
    user_id = fields.String(required=True)

    title = fields.String(validate=validate.Length(min=1, max=32))
    rating = fields.Integer(
        strict=True, validate=validate.Range(min=0, max=5), required=True
    )

class ReviewManager(Resource):
    def get(self, **kwargs):
        parser = reqparse.RequestParser()
        parser.add_argument("carpark_id", type=int, required=True)
        args = parser.parse_args()

        supabase = get_database_connection()
        response = (
            supabase.table("reviews")
            .select("title", "review")
            .eq("carpark_id", args["carpark_id"])
            .execute()
        )

        if response.data:
            return {"data": [ReviewSchema().dump(rev) for rev in response.data]}, 200
        else:
            return {"error": "Car park does not exist"}

    def post(self):
        data = request.get_json()
        
        if not data:
            return {"error": "No JSON data provided"}, 400
            
        title = data.get("title")
        review = data.get("review")
        
        if not title or review is None:
            return {"error": "Missing required fields: title and review"}, 400

        try:
            supabase = get_database_connection_admin()
            response = (
                supabase.table("reviews")
                .insert(
                    {
                        "title": title,
                        "review": review,
                    }
                )
                .execute()
            )
            return {"data": response.data, "message": "Review submitted successfully"}, 201

        except Exception as e:
            print(f"Error submitting review: {e}")
            return {"error": str(e)}, 500
            

    def delete(self):
        parser = reqparse.RequestParser()
        parser.add_argument("review_id", type=int, required=True)
        args = parser.parse_args()

        try:

            supabase = get_database_connection()
            response = supabase.table("reviews").delete().eq("review_id", args["review_id"]).execute()
            return {"message": "Review deleted successfully"}, 200

        except Exception as e:
            return {"error": str(e)}, 500
