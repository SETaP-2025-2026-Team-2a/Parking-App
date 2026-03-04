from flask_restful import Resource, reqparse
from werkzeug.security import generate_password_hash, check_password_hash


def getUser(name, lastname, email=None, password=None, process="Get User"):
    # Implement logic to retrieve user information based on the username
    # This is a placeholder implementation, replace with actual database query
    result = False
    if process == "getUser":
        if name == "test" and lastname == "user":
            result = True
            return {
                "process": "Get User",
                "name": name,
                "lastname": lastname,
                "email": "testuser@example.com",
                "result": result
            }
        return {
            "process": "Get User",
            "name": name,
            "lastname": lastname,
            "email": email, 
            "result": result
        }
    if process == "Sign In":
        return {
            "process": "Sign In",
            "name": name,
            "lastname": lastname,
            "email": email, 
            "password_hash": generate_password_hash("Test"), #placeholder hash, replace with actual hash from database
            "result": result
        }


def deleteUser(name, lastname):
    # Implement logic to delete a user based on the name and lastname
    # This is a placeholder implementation, replace with actual database deletion
    result = True
    return {
        "process": "Delete User",
        "name": name,
        "lastname": lastname,
        "result": result
    }


def updateUser(name, lastname, email=None, password_hash=None):
    # Implement logic to update a user based on the name and lastname
    # This is a placeholder implementation, replace with actual database update
    print(f"Updating user: {name} {lastname}, email: {email}, password_hash: {password_hash}")
    return {
        "process": "Update User",
        "name": name,
        "lastname": lastname,
        "email": email,
        "result": True
    }


def createUser(name, lastname, email, password):

        password_hash = generate_password_hash(password)
        print(f"Creating user: {name} {lastname}, {email}, {password_hash}")

        return {
            "process": "Create User",
            "name": name,
            "lastname": lastname,
            "email": email,
            "result": True
        }, 201

def validateUser(name, lastname, password):
    user = getUser(name, lastname, password=password, process="Sign In")
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

class UsersResource(Resource):
    def post(self):
        parser = reqparse.RequestParser()
        parser.add_argument("name", type=str, required=True)
        parser.add_argument("lastname", type=str, required=True)
        parser.add_argument("email", type=str, required=True)
        parser.add_argument("password", type=str, required=True)
        args = parser.parse_args()

        return createUser(args["name"], args["lastname"], args["email"], args["password"])

class UserResource(Resource):
    def get(self, name, lastname):
        return getUser(name, lastname)

    def delete(self, name, lastname):
        return deleteUser(name, lastname), 200

    def put(self, name, lastname):
        parser = reqparse.RequestParser()
        parser.add_argument("email", type=str, required=False)
        parser.add_argument("password", type=str, required=False)
        args = parser.parse_args()

        if not args.get("email") and not args.get("password"):
            return {
                "process": "Update User",
                "error": "At least one field is required: email or password"
            }, 400

        password_hash = generate_password_hash(args["password"]) if args.get("password") else None
        return updateUser(name, lastname, email=args.get("email"), password_hash=password_hash), 200
