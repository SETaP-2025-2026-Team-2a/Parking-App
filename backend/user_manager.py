from flask import Flask, request, jsonify
from flask_restful import Resource
from werkzeug.security import generate_password_hash


def getUser(username):
    # Implement logic to retrieve user information based on the username
    # This is a placeholder implementation, replace with actual database query
    # Ensure that the user exists and handle any potential errors
    result = True
    if username == "testuser":
        return {
            "process": "Get User",
            "username": "testuser", 
            "email": "testuser@example.com"}
    return {
            "process": "Get User",
            "username": username, 
            "result": result
            }

def register_user_routes(server):
    @server.route('/api/users', methods=['POST'])
    def createUser():
        data = request.get_json(silent=True) or {}
        username = data.get('username') or data.get('name')
        email = data.get('email')
        password = data.get('password')

        if not username or not email or not password:
            return jsonify({
                "process": "Create User",
                "error": "Missing required fields: username, email, and password"
            }), 400

        username = username
        email = email
        password = generate_password_hash(password)
        print(f"Creating user: {username}, {email}, {password}")
        # Implement logic to create a new user with the provided username, email, and password
        # This is a placeholder implementation, replace with actual database insertion
        return jsonify({
            "process": "Create User",
            "username": username,
            "email": email,
            "result": True,
        }), 201

def deleteUser(username):
    # Implement logic to delete a user based on the username
    # This is a placeholder implementation, replace with actual database deletion
    # Ensure that the user exists before attempting to delete and handle any potential errors 
    result = True
    return {
            "Process": "Delete User",
            "username": username, 
            "result": result
            }