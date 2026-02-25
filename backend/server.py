import flask
from flask_restful import Api
from flask_cors import CORS

from car_park_manager import ParkingSpots

server= flask.Flask(__name__)
CORS(server) 
api = Api(server)

api.add_resource(ParkingSpots, '/parking-spots')
api.add_resource('/login')
if __name__ == '__main__':
    server.run(debug=True, host='0.0.0.0', port=8080)