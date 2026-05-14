from modules import get_database_connection_admin
from car_park_manager import CarParkSchema
from werkzeug.security import generate_password_hash


# default car parks used to make sure database is populated with car aprks from the start
def default_car_parks():
    supabase = get_database_connection_admin()
    for car_park in carparks:
        # Check if car park already exists
        existing = supabase.table("carpark").select("*").eq("name", car_park["name"]).execute()
        
        if existing.data:
            continue
        
        # longitude and latitude are grabbed from string and converted into to GeoJson to allow input into database
        lat, lon = map(float, car_park["location"].split(","))
        location_geom = {
            "type": "Point",
            "coordinates": [lon, lat]
        }
        
        response = supabase.table("carpark").insert({
        "name": car_park["name"],
        "location": location_geom,
        "is_restricted": False,
        "space_type" : "CAR",
        }).execute()

        if not response.data:
            return {
                "error": "Failed to create car park"
            }, 500

        return {
            "data": CarParkSchema().dump(response.data[0])
        }, 201

carparks = [
    {"name": "gunwharf quays", "spaces": 500, "location": "50.796371295864176, -1.105699549149126"},
    {"name": "Southsea car park", "spaces": 200, "location": "50.78297038437193, -1.068130813480475"},
    {"name": "Fratton station car park", "spaces": 150, "location": "50.7960469693931, -1.068645797867113"},
    {"name": "Cosham town centre", "spaces": 180, "location": "50.84190601263039, -1.0815741730000212"},
    {"name": "Portaland car park", "spaces": 50, "location": "50.7991655930562, -1.0990798168572316"},
    {"name": "multi-storey", "spaces": 200, "location": "50.789373484485104, -1.0746539455489148"},
]

# default users are used for demo purposes so a test user can still use the software
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

        if not response.data:
            return {
                "error": "Failed to create default user"
            }, 500

        return {
            "data": response.data[0]
        }, 201

    return {
        "data": existing.data[0]
    }, 200