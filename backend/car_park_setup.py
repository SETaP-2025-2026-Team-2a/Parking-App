from modules import get_database_connection
from car_park_manager import CarParkSchema

def default_car_parks():
    supabase = get_database_connection()
    for car_park in carparks:
        # Check if car park already exists
        existing = supabase.table("carpark").select("*").eq("name", car_park["name"]).execute()
        
        if existing.data:
            continue
        
        # Convert coordinates to GeoJSON format (longitude, latitude)
        lat, lon = map(float, car_park["location"].split(","))
        location_geom = {
            "type": "Point",
            "coordinates": [lon, lat]
        }
        
        response = supabase.table("carpark").insert({
        "name": car_park["name"],
        "location": location_geom
        }).execute()

        if response.error:
            return {
                "error": "Failed to create car park"
            }, 500

        return {
            "data": CarParkSchema().dump(response.data[0])
        }, 201

carparks = [
    {"name": "gunwharf quays", "spaces": 500, "location": "40.785091,-73.968285"},
    {"name": "Portaland car park", "spaces": 50, "location": "40.712776,-74.005974"},
    {"name": "multi-storey", "spaces": 200, "location": "40.641311,-73.778139"},
]