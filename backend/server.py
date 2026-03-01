import flask
from flask_restful import Api, Resource
from flask_cors import CORS

from car_park_manager import ParkingSpots
from search_manager import SearchManager

server= flask.Flask(__name__)
CORS(server) 
api = Api(server)

api.add_resource(ParkingSpots, '/parking-spots')
api.add_resource(SearchManager, '/search')

register_user_routes(server)

if __name__ == '__main__':
    server.run(debug=True, host='0.0.0.0', port=8080)