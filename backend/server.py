import flask
from flask_restful import Api, Resource
from flask_cors import CORS

from car_park_manager import CarPark
from search_manager import SearchManager
from user_manager import UserResource, UsersResource
from authentication_manager import LoginResource


server= flask.Flask(__name__)
CORS(server) 
api = Api(server)

api.add_resource(CarPark, '/car-park') # GET car park
api.add_resource(SearchManager, '/search') # GET search query
api.add_resource(UsersResource, '/users')  # POST create
api.add_resource(UserResource, '/users/<string:email>') # GET read, PUT update
api.add_resource(LoginResource, "/login") # POST login



if __name__ == '__main__':
    server.run(debug=True, host='0.0.0.0', port=8080)