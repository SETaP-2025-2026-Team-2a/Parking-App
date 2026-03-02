from flask_restful import Resource, reqparse
from werkzeug.security import generate_password_hash


def getUser(username):
    # Implement logic to retrieve user information based on the username
    # This is a placeholder implementation, replace with actual database query
    result = False
    if username == "testuser":
        result = True
    if username == "testuser":
        return {
            "process": "Get User",
            "username": "testuser",
            "email": "testuser@example.com"
        }
    return {
        "process": "Get User",
        "username": username,
        "result": result
    }


def deleteUser(username):
    # Implement logic to delete a user based on the username
    # This is a placeholder implementation, replace with actual database deletion
    result = True
    return {
        "process": "Delete User",
        "username": username,
        "result": result
    }


def updateUser(username, email=None, password_hash=None):
    # Implement logic to update a user based on the username
    # This is a placeholder implementation, replace with actual database update
    print(f"Updating user: {username}, email: {email}, password_hash: {password_hash}")
    return {
        "process": "Update User",
        "username": username,
        "email": email,
        "result": True
    }


def createUser(username, email, password):

        password_hash = generate_password_hash(password)
        print(f"Creating user: {username}, {email}, {password_hash}")

        return {
            "process": "Create User",
            "username": username,
            "email": email,
            "result": True
        }, 201


class UsersResource(Resource):
    def post(self):
        parser = reqparse.RequestParser()
        parser.add_argument("username", type=str, required=True)
        parser.add_argument("email", type=str, required=True)
        parser.add_argument("password", type=str, required=True)
        args = parser.parse_args()

        return createUser(args["username"], args["email"], args["password"])

class UserResource(Resource):
    def get(self, username):
        return getUser(username), 200

    def delete(self, username):
        return deleteUser(username), 200

    def put(self, username):
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
        return updateUser(username, email=args.get("email"), password_hash=password_hash), 200
