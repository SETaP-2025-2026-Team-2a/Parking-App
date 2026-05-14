# Review management API endpoints
from datetime import datetime, timezone

from flask_restful import Resource, reqparse
from flask import request
from marshmallow import Schema, fields, validate

from modules import get_database_connection, get_database_connection_admin

class ReviewSchema(Schema):
    title = fields.String(required=True, validate=validate.Length(min=1, max=255))
    review = fields.Integer(
        strict=True, validate=validate.Range(min=0, max=5), required=True
    )
    comment = fields.String(required=True, validate=validate.Length(min=1, max=1000))

class ReviewManager(Resource):
    def get(self, **kwargs):
        # Use admin connection to ensure access to all review rows/columns
        supabase = get_database_connection_admin()

        try:
            # grabs all reviews with an order of review id in DESC order
            response = (
                supabase.table("reviews")
                .select("review_id, title, review, comment")
                .order("review_id", desc=True)
                .execute()
            )
        except Exception as e:
            print(f"Error fetching reviews: {e}")
            return {"data": []}, 200

        reviews = []
        for review in response.data or []:
            reviews.append(
                {
                    "review_id": review.get("review_id"),
                    "title": review.get("title") or "Unknown car park",
                    "review": int(review.get("review") or 0),
                    "comment": review.get("comment") or "",
                }
            )

        return {"data": reviews}, 200

    def post(self):
        data = request.get_json()

        if not data:
            return {"error": "No JSON data provided"}, 400

        title = data.get("title")
        review = data.get("review")
        comment = data.get("comment")

        if not title or review is None or not comment:
            return {
                "error": "Missing required fields: title, review, and comment"
            }, 400

        try:
            supabase = get_database_connection_admin()
            response = (
                supabase.table("reviews")
                .insert(
                    {
                        "title": title,
                        "review": review,
                        "comment": comment,
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
