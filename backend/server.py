import flask
from flask_restful import Api
from flask_cors import CORS

from car_park_manager import CarPark
from search_manager import SearchManager, SearchManagerAll
from user_manager import UserResource
from authentication_manager import LoginResource, SignupResource
from review_manager import ReviewManager
from session_manager import ParkingSessionManager
from payment_manager import Payment
from car_park_setup import default_car_parks, default_user
from modules import get_database_connection

server= flask.Flask(__name__)
CORS(server) 
api = Api(server)

api.add_resource(CarPark, '/car-park') # GET car park
api.add_resource(SearchManager, '/search') # GET search query
api.add_resource(UserResource, '/users/<string:email>') # GET read, PUT update
api.add_resource(LoginResource, "/login") # POST login
api.add_resource(SignupResource, "/signup") # POST create account
api.add_resource(ReviewManager, "/review") # POST add review, GET get reviews for specific car park, DELETE
api.add_resource(ParkingSessionManager, "/parking-session") # POST start session, PUT end session, GET get active sessions for user
api.add_resource(Payment, "/payment") # POST process payment
api.add_resource(SearchManagerAll, "/search-all") # GET all car parks for testing



if __name__ == '__main__':
    default_car_parks()
    supabase = get_database_connection()
    response = supabase.table("User").select("*").execute()
    print(response.data)
    default_user()

    server.run(debug=True, host='0.0.0.0', port=8080)
    