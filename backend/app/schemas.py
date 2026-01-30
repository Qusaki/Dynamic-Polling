from pydantic import BaseModel, EmailStr
from typing import List, Optional
from datetime import datetime # New import
from .models import QuestionType

class UserCreate(BaseModel):
    email: EmailStr
    password: str

class OptionCreate(BaseModel):
    text: str

class QuestionCreate(BaseModel):
    text: str
    type: QuestionType
    options: Optional[List[str]] = None

class PollCreate(BaseModel):
    title: str
    description: Optional[str] = None
    questions: List[QuestionCreate]

class PollCreateResponse(BaseModel):
    poll_id: int
    access_code: str

class PollStatusUpdate(BaseModel):
    is_active: bool

class PollUpdate(BaseModel):
    title: str
    description: Optional[str] = None

class VoteCreate(BaseModel):
    question_id: int
    response_value: str

class Option(BaseModel):
    id: int
    text: str

    class Config:
        from_attributes = True

class Question(BaseModel):
    id: int
    text: str
    type: QuestionType
    order: int
    class Config:
        from_attributes = True

class Poll(BaseModel):
    id: int
    title: str
    description: Optional[str] = None
    access_code: str
    is_active: bool
    created_at: datetime # New field
    questions: List[Question] = []

    class Config:
        from_attributes = True