import sys
import os
sys.path.append(os.path.dirname(os.path.dirname(__file__)))
from modules import get_database_connection_admin

sup = get_database_connection_admin()

for name in ("Reviews", "reviews"):
    try:
        resp = sup.table(name).select("*").execute()
        print(f"Table {name}: status={getattr(resp,'status_code',None)} data={resp.data}")
    except Exception as e:
        print(f"Table {name} error: {e}")

# Try selecting specific columns to replicate API behavior
try:
    resp2 = sup.table('reviews').select('title, review, comment, user_email, user_name, created_at').execute()
    print('Select specific columns:', resp2.data)
except Exception as e:
    print('Select specific columns error:', e)
