import os
from dotenv import load_dotenv
from supabase import Client, create_client

load_dotenv()  # Load environment variables from .env file

SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_ANON_KEY = os.getenv("SUPABASE_ANON_KEY")
SUPABASE_SERVICE_ROLE_KEY = os.getenv("SUPABASE_SERVICE_ROLE_KEY")

def get_database_connection():
    supabase: Client = create_client(SUPABASE_URL, SUPABASE_ANON_KEY)
    return supabase

def get_database_connection_admin():
    """Get admin connection using service role key (bypasses RLS)"""
    supabase: Client = create_client(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)
    return supabase