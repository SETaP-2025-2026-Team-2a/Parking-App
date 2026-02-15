import flask
from flask_restful import Resource, Api
from flask_cors import CORS
app = flask.Flask(__name__)
CORS(app) 
api = Api(app)
class ParkingSpots(Resource):
    def get(self):
        data = [
            {
                'name': 'gunwharf quays',
                'spaces': 100,
                'distance': 0.5,
            },
            {
                'name': 'portsmouth harbour',
                'spaces': 50,
                'distance': 0.8,
            },
            {
                'name': 'fratton park',
                'spaces': 20,
                'distance': 1.2,
            },
        ]
        return {
            'data': data,
            }
api.add_resource(ParkingSpots, '/')
if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=8080)