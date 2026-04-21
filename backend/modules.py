import os
from dotenv import load_dotenv
from supabase import Client, create_client

load_dotenv()  # Load environment variables from .env file

SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_ANON_KEY = os.getenv("SUPABASE_ANON_KEY")

def get_database_connection():
    supabase: Client = create_client(SUPABASE_URL, SUPABASE_ANON_KEY)
    return supabase