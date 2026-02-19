from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker, declarative_base
from .config import settings

engine = create_async_engine(
    # Render optimization: Limit pool size to avoid "too many clients" errors
    # on free tier which has a limit of 10-20 connections.
    settings.DATABASE_URL,
    echo=False,  # Disable echo in production for performance
    pool_size=5,
    max_overflow=10,
    connect_args={"statement_cache_size": 0},
)
async_session = sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)

Base = declarative_base()


async def get_session() -> AsyncSession:
    async with async_session() as session:
        yield session
