from flask_restful import Resource, reqparse
from werkzeug.security import generate_password_hash, check_password_hash


def getUser(name, lastname, email=None, password=None, ):
    # Implement logic to retrieve user information based on the username
    # This is a placeholder implementation, replace with actual database query
    result = False
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


