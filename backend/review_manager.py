from flask_restful import Resource, reqparse
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
            supabase.table("Reviews")
            .select("title", "review")
            .eq("carpark_id", args["carpark_id"])
            .execute()
        )

        if response.data:
            return {"data": [ReviewSchema().dump(rev) for rev in response.data]}, 200
        else:
            return {"error": "Car park does not exist"}

    def post(self):
        parser = reqparse.RequestParser()
        parser.add_argument("title", type=str, required=True)
        parser.add_argument("review", type=int, required=True)
        parser.add_argument("comment", type=str, required=True)
        args = parser.parse_args()

        try:

            supabase = get_database_connection_admin()
            response = (
                supabase.table("Reviews")
                .insert(
                    {
                        "title": args["title"],
                        "review": args["review"],
                    }
                )
                .execute()
            )
            return {"data": response.data, "message": "Review submitted successfully"}, 201

        except Exception as e:
            return {"error": str(e)}, 500

    def delete(self):
        parser = reqparse.RequestParser()
        parser.add_argument("review_id", type=int, required=True)
        args = parser.parse_args()

        try:

            supabase = get_database_connection()
            response = supabase.table("Reviews").delete().eq("review_id", args["review_id"]).execute()
            return {"message": "Review deleted successfully"}, 200

        except Exception as e:
            return {"error": str(e)}, 500
