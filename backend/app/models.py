import enum
from sqlalchemy import (
    Column,
    Integer,
    String,
    Boolean,
    DateTime,
    ForeignKey,
    Text,
    Enum as SQLAlchemyEnum,
    func,
)
from sqlalchemy.orm import relationship
from .database import Base


class User(Base):
    __tablename__ = "users"
    id = Column(Integer, primary_key=True, index=True)
    email = Column(String, unique=True, index=True, nullable=False)
    password_hash = Column(String, nullable=False)
    polls = relationship("Poll", back_populates="instructor")


class Poll(Base):
    __tablename__ = "polls"
    id = Column(Integer, primary_key=True, index=True)
    title = Column(String, nullable=False)
    description = Column(Text)
    instructor_id = Column(Integer, ForeignKey("users.id"))
    access_code = Column(String, unique=True, index=True, nullable=False)
    is_active = Column(Boolean, default=True)
    instructor = relationship("User", back_populates="polls")
    questions = relationship("Question", back_populates="poll", cascade="all, delete")


class QuestionType(str, enum.Enum):
    RATING = "RATING"
    MULTIPLE_CHOICE = "MULTIPLE_CHOICE"
    OPEN_ENDED = "OPEN_ENDED"


class Question(Base):
    __tablename__ = "questions"
    id = Column(Integer, primary_key=True, index=True)
    poll_id = Column(Integer, ForeignKey("polls.id"))
    text = Column(String, nullable=False)
    type = Column(SQLAlchemyEnum(QuestionType), nullable=False)
    order = Column(Integer, nullable=False)
    poll = relationship("Poll", back_populates="questions")
    options = relationship("Option", back_populates="question", cascade="all, delete")
    votes = relationship("Vote", back_populates="question", cascade="all, delete")


class Option(Base):
    __tablename__ = "options"
    id = Column(Integer, primary_key=True, index=True)
    question_id = Column(Integer, ForeignKey("questions.id"))
    text = Column(String, nullable=False)
    question = relationship("Question", back_populates="options")


class Vote(Base):
    __tablename__ = "votes"
    id = Column(Integer, primary_key=True, index=True)
    question_id = Column(Integer, ForeignKey("questions.id"))
    response_value = Column(String, nullable=False)
    timestamp = Column(DateTime(timezone=True), server_default=func.now())
    question = relationship("Question", back_populates="votes")
