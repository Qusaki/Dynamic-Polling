from fastapi import Depends, HTTPException, status, Request
from fastapi.security import OAuth2PasswordBearer
from jose import JWTError, jwt
from passlib.context import CryptContext
from datetime import datetime, timedelta
from typing import Optional
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select

from . import models
from .database import get_session
from .config import settings


pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/auth/token")

# Define a constant for the credentials exception to avoid repetition.
CREDENTIALS_EXCEPTION = HTTPException(
    status_code=status.HTTP_401_UNAUTHORIZED,
    detail="Could not validate credentials",
    headers={"WWW-Authenticate": "Bearer"},
)

def get_password_hash(password: str) -> str:
    """Hashes a plain-text password using bcrypt."""
    return pwd_context.hash(password)


def verify_password(plain_password: str, hashed_password: str) -> bool:
    """Verifies a plain-text password against a hashed password."""
    return pwd_context.verify(plain_password, hashed_password)


def create_access_token(data: dict, expires_delta: Optional[timedelta] = None) -> str:
    """Creates a new JWT access token."""
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, settings.SECRET_KEY, algorithm=settings.ALGORITHM)
    return encoded_jwt

def _decode_token_payload(token: str) -> dict:
    """Decodes the JWT token and returns the payload, handling errors."""
    try:
        payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
        return payload
    except JWTError:
        raise CREDENTIALS_EXCEPTION

def _refresh_token_if_needed(request: Request, payload: dict):
    """Checks token expiration and refreshes it if it's past half its life."""
    email: Optional[str] = payload.get("sub")
    exp: Optional[int] = payload.get("exp")

    if email is None or exp is None:
        raise CREDENTIALS_EXCEPTION

    token_lifetime = timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    time_until_expiry = datetime.fromtimestamp(exp) - datetime.utcnow()

    if time_until_expiry < (token_lifetime / 2):
        new_token = create_access_token(data={"sub": email})
        request.state.refreshed_token = new_token


async def get_current_user_and_refresh_token(
    request: Request, 
    token: str = Depends(oauth2_scheme), 
    db: AsyncSession = Depends(get_session)
) -> models.User:
    """
    Dependency to get the current user from a token, and refresh the token if needed.
    """
    payload = _decode_token_payload(token)
    _refresh_token_if_needed(request, payload)
    
    email: Optional[str] = payload.get("sub")
    if email is None:
        raise CREDENTIALS_EXCEPTION
    
    result = await db.execute(select(models.User).where(models.User.email == email))
    user = result.scalars().first()

    if user is None:
        raise CREDENTIALS_EXCEPTION
    return user
