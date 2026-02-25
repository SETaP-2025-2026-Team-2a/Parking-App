from flask_restful import Resource

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