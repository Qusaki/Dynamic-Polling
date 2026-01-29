from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.orm import Session
from datetime import timedelta

from .. import schemas, models, security
from ..database import get_db

router = APIRouter(
    prefix="/auth",
    tags=["Authentication"]
)

@router.post("/register", response_model=schemas.Instructor)
def register_instructor(instructor: schemas.InstructorCreate, db: Session = Depends(get_db)):
    db_instructor = db.query(models.Instructor).filter(models.Instructor.email == instructor.email).first()
    if db_instructor:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email already registered"
        )
    
    hashed_password = security.get_password_hash(instructor.password)
    new_instructor = models.Instructor(
        full_name=instructor.full_name,
        email=instructor.email,
        password_hash=hashed_password
    )
    db.add(new_instructor)
    db.commit()
    db.refresh(new_instructor)
    return new_instructor


@router.post("/token", response_model=schemas.Token)
def login_for_access_token(form_data: OAuth2PasswordRequestForm = Depends(), db: Session = Depends(get_db)):
    instructor = db.query(models.Instructor).filter(models.Instructor.email == form_data.username).first()
    if not instructor or not security.verify_password(form_data.password, instructor.password_hash):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password",
            headers={"WWW-Authenticate": "Bearer"},
        )

    
    access_token_expires = timedelta(minutes=security.ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = security.create_access_token(
        data={"sub": instructor.email}, expires_delta=access_token_expires
    )
    return {"access_token": access_token, "token_type": "bearer"}
