from modules import get_database_connection_admin
from car_park_manager import CarParkSchema
from werkzeug.security import generate_password_hash

def default_car_parks():
    supabase = get_database_connection_admin()
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
        "location": location_geom,
        "is_restricted": False,
        "space_type" : ["Car", "Motorcycle", "Disabled"],
        }).execute()

        if response.error:
            return {
                "error": "Failed to create car park"
            }, 500

        return {
            "data": CarParkSchema().dump(response.data[0])
        }, 201

carparks = [
    {"name": "gunwharf quays", "spaces": 500, "location": "-1.1062,50.7954621"},
    {"name": "Portaland car park", "spaces": 50, "location": "40.712776,-74.005974"},
    {"name": "multi-storey", "spaces": 200, "location": "40.641311,-73.778139"},
]

def default_user():
    supabase = get_database_connection_admin()
    existing = supabase.table("User").select("*").eq("email", "admin@example.com").execute()

    if not existing.data:
        response = supabase.table("User").insert({
            "email": "admin@example.com",
            "password_hash": generate_password_hash("admin123"),
            "payment_token": "",
            "first_name": "Admin",
            "last_name": "User"
        }).execute()

        if response.error:
            return {
                "error": "Failed to create default user"
            }, 500

        return {
            "data": response.data[0]
        }, 201

    return {
        "data": existing.data[0]
    }, 200