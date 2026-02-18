import sys
import os
import asyncio
from sqlalchemy.ext.asyncio import create_async_engine
from sqlalchemy import text

# Add current directory to path
sys.path.append(os.getcwd())

from app.config import settings
from app.database import engine


async def verify_fix():
    print(f"Testing connection to: {settings.DATABASE_URL}")

    try:
        # Check if statement_cache_size is set to 0 in the engine's connect_args
        # Note: The way connect_args are stored might vary, but we can check if we can execute a query
        # without the duplicate prepared statement error which was happening before.

        async with engine.connect() as conn:
            # Execute a simple query
            result = await conn.execute(text("SELECT 1"))
            print(f"Connection successful! Result: {result.scalar()}")

            # Execute it again to ensure no caching issues if we were to loop
            result = await conn.execute(text("SELECT 1"))
            print(f"Second execution successful! Result: {result.scalar()}")

    except Exception as e:
        print(f"Verification FAILED: {e}")
        import traceback

        traceback.print_exc()


if __name__ == "__main__":
    if sys.platform == "win32":
        asyncio.set_event_loop_policy(asyncio.WindowsSelectorEventLoopPolicy())
    asyncio.run(verify_fix())
