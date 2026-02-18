import httpx
import os
import asyncio
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

async def ping_self():
    app_url = os.getenv("APP_URL")
    if not app_url:
        logger.error("APP_URL environment variable is not set.")
        return

    # Append /docs or /health if you have a specific health endpoint
    # Using /docs as it's a standard FastAPI endpoint that should return 200 OK
    target_url = f"{app_url}/docs" 
    
    logger.info(f"Pinging {target_url}...")
    
    async with httpx.AsyncClient() as client:
        try:
            response = await client.get(target_url, timeout=10.0)
            if response.status_code == 200:
                logger.info("Ping successful!")
            else:
                logger.warning(f"Ping received status code: {response.status_code}")
        except Exception as e:
            logger.error(f"Ping failed: {e}")

if __name__ == "__main__":
    asyncio.run(ping_self())
