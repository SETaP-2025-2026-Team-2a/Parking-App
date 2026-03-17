from flask_restful import Resource, reqparse
from werkzeug.security import generate_password_hash, check_password_hash
import os
from datetime import datetime, timedelta, timezone

import jwt


JWT_SECRET = os.getenv("JWT_SECRET", "change-me-in-production")
JWT_ALGORITHM = "HS256"
JWT_EXPIRES_MINUTES = 60


def create_session_token(user):
    now = datetime.now(timezone.utc)
    payload = {
        "sub": f"{user['name']}:{user['lastname']}",
        "name": user["name"],
        "lastname": user["lastname"],
        "iat": int(now.timestamp()),
        "exp": int((now + timedelta(minutes=JWT_EXPIRES_MINUTES)).timestamp()),
    }
    return jwt.encode(payload, JWT_SECRET, algorithm=JWT_ALGORITHM)

def getUser(name, lastname, email=None, password=None, ):
    # Implement logic to retrieve user information based on the username
    # This is a placeholder implementation, replace with actual database query
    dbQuery = name # Placeholder for database query to get user by name and lastname
    result = False
    if dbQuery: # If user is found in the database
        result = True

    return {
            "name": name,
            "lastname": lastname,
            "email": email, 
            "password_hash": generate_password_hash(password), #placeholder hash, replace with actual hash from database   
            "result": result
        }

def validateUser(name, lastname, password):
    user = getUser(name, lastname, password=password)
    if user["result"] == False:
        return {"process": "Sign In", "error": "Invalid credentials"}, 401

    if not check_password_hash(user["password_hash"], password):
        return {"process": "Sign In", "result": False, "error": "Invalid credentials"}, 401

    token = create_session_token(user)
    return {
        "process": "Sign In",
        "result": True,
        "name": user["name"],
        "lastname": user["lastname"],
        "access_token": token,
        "token_type": "Bearer",
        "expires_in": JWT_EXPIRES_MINUTES * 60,
    }, 200


def deleteUser(username, password):
    user = getUser(username, password=password)
    if user["result"] == False:
        return {"process": "Delete User", "error": "Invalid credentials"}, 401
    if not check_password_hash(user["password_hash"], password):
        return {"process": "Delete User", "result": False, "error": "Invalid credentials"}, 401
    # Implement logic to delete a user based on the username
    # This is a placeholder implementation, replace with actual database delete
    print(f"Deleting user: {username}")
    return {
        "process": "Delete User",
        "name": username,
        "result": True
    }, 200


class LoginResource(Resource):
    def post(self):
        parser = reqparse.RequestParser()
        parser.add_argument("name", type=str, required=True)
        parser.add_argument("lastname", type=str, required=True)
        parser.add_argument("password", type=str, required=True)
        args = parser.parse_args()

        print(args)
        return validateUser(args["name"], args["lastname"], args["password"])
    
    def delete(self):
        parser = reqparse.RequestParser()
        parser.add_argument("username", type=str, required=True)
        parser.add_argument("password", type=str, required=True)
        args = parser.parse_args()
        return deleteUser(args["username"], args["password"])
