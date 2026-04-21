from flask_restful import Resource, reqparse
from modules import get_database_connection
from werkzeug.security import check_password_hash

class Payment(Resource):
    def post(self):
        parser = reqparse.RequestParser()
        user_id = parser.add_argument("user_id", type=int, required=True)
        amount = parser.add_argument("amount", type=float, required=True)
        payment_method = parser.add_argument("payment_method", type=str, required=True, choices=["credit_card", "paypal", "bank_transfer"])
        password = parser.add_argument("password", type=str, required=True)

        db = get_database_connection()
        user_response = db.table("users").select("password").eq("user_id", user_id).execute()
        if not user_response.data:
            return {
                "error": "User not found"
            }, 404
        stored_password = user_response.data[0]["password"]
        if not check_password_hash(stored_password, password):
            return {
                "error": "Invalid password",
                "details": "Authentication failed for the user"
            }, 401
        args = parser.parse_args()

        # Validate payment details in a real application this would involve more complex logic and integration with a payment gateway
        # Here it would be integrated with a payment gateway like Stripe or PayPal
        # But as this isn't a real implementation, setting it up with a gatway is not a viable option
        # we will assume the payment is always successful after simple validation checks

        if amount <= 0:
            return {
                "error": "Invalid payment amount",
                "details": "Amount must be greater than zero"
            }, 400
        
        if payment_method not in ["credit_card", "paypal", "bank_transfer"]:
            return {
                "error": "Invalid payment method",
                "details": "Payment method must be one of: credit_card, paypal, bank_transfer"
            }, 400
        

        return {
            "message": f"Payment of ${amount} for user {user_id} processed successfully."
        }, 200