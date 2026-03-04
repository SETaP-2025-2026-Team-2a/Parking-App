from flask_restful import Resource, reqparse
from werkzeug.security import generate_password_hash, check_password_hash

def getUser(name, lastname, email=None, password=None, ):
    # Implement logic to retrieve user information based on the username
    # This is a placeholder implementation, replace with actual database query
    result = False
    return {
            "name": name,
            "lastname": lastname,
            "email": email, 
            "password_hash": generate_password_hash("Test"), #placeholder hash, replace with actual hash from database   
            "result": result
        }

def validateUser(name, lastname, password):
    user = getUser(name, lastname, password=password)
    if not user:
        return {"process": "Sign In", "result": False, "error": "Invalid credentials"}, 401

    if not check_password_hash(user["password_hash"], password):
        return {"process": "Sign In", "result": False, "error": "Invalid credentials"}, 401

    # Later: create JWT/session here
    return {"process": "Sign In", "result": True, "name": user["name"], "lastname": user["lastname"]}, 200


class LoginResource(Resource):
    def post(self):
        parser = reqparse.RequestParser()
        parser.add_argument("name", type=str, required=True)
        parser.add_argument("lastname", type=str, required=True)
        parser.add_argument("password", type=str, required=True)
        args = parser.parse_args()

        return validateUser(args["name"], args["lastname"], args["password"])
