
import sys
import os
import asyncio
from sqlalchemy.ext.asyncio import create_async_engine
from sqlalchemy import text

# Add current directory to path
sys.path.append(os.getcwd())

from app.config import settings

async def check_db_connection():
    print(f"Testing connection to: {settings.DATABASE_URL}")
    try:
        engine = create_async_engine(settings.DATABASE_URL, echo=False)
        async with engine.connect() as conn:
            result = await conn.execute(text("SELECT 1"))
            print(f"Connection successful! Result: {result.scalar()}")
    except Exception as e:
        print(f"Connection FAILED: {e}")
        # Check for common asyncpg errors
        if "password authentication failed" in str(e):
            print("HINT: Check the password in your .env file.")
        elif "does not exist" in str(e):
            print("HINT: Ensure the database name exists in Postgres.")
        elif "Connection refused" in str(e):
            print("HINT: Ensure PostgreSQL is running on localhost:5432.")

if __name__ == "__main__":
    if sys.platform == 'win32':
        asyncio.set_event_loop_policy(asyncio.WindowsSelectorEventLoopPolicy())
    asyncio.run(check_db_connection())
