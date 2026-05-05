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
    user_email = fields.String(required=True, validate=validate.Length(min=1, max=255))
    user_name = fields.String(required=True, validate=validate.Length(min=1, max=255))
    created_at = fields.String(required=True)

class ReviewManager(Resource):
    def get(self, **kwargs):
        email = request.args.get("email", type=str)

        # Use admin connection to ensure access to all review rows/columns in this dev environment
        supabase = get_database_connection_admin()

        # Try to read minimal known columns first (these exist in older DB seeds)
        select_cols = "review_id, title, review"
        try:
            # Prefer ordering by created_at when available, otherwise fall back to review_id
            try:
                response = (
                    supabase.table("reviews").select(select_cols).order("created_at", desc=True).execute()
                )
            except Exception:
                response = (
                    supabase.table("reviews").select(select_cols).order("review_id", desc=True).execute()
                )
        except Exception as e:
            print(f"Error fetching reviews minimal columns: {e}")
            return {"data": []}, 200

        reviews = []
        for review in response.data or []:
            reviews.append(
                {
                    "title": review.get("title") or "Unknown car park",
                    "review": int(review.get("review") or 0),
                    "comment": review.get("comment") or "",
                    "user_email": review.get("user_email") or email,
                    "user_name": review.get("user_name") or review.get("title") or "Unknown",
                    "created_at": review.get("created_at") or datetime.now(timezone.utc).isoformat(),
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
        user_email = data.get("user_email")
        user_name = data.get("user_name")

        if not title or review is None or not comment or not user_email or not user_name:
            return {
                "error": "Missing required fields: title, review, comment, user_email, and user_name"
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
                        "user_email": user_email,
                        "user_name": user_name,
                        "created_at": datetime.now(timezone.utc).isoformat(),
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
