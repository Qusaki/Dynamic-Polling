from fastapi import FastAPI, Depends, HTTPException, WebSocket, WebSocketDisconnect, status
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from sqlalchemy import func
from . import models, auth, schemas
from .database import engine, get_session, Base
from .websocket_manager import ConnectionManager
from pydantic import BaseModel
from typing import List
import random
import string
import json
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.orm import selectinload

app = FastAPI()

origins = ["*"]

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

manager = ConnectionManager()

@app.on_event("startup")
async def startup():
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

@app.post("/auth/register", status_code=201)
async def register_user(user_data: schemas.UserCreate, db: AsyncSession = Depends(get_session)):
    hashed_password = auth.get_password_hash(user_data.password)
    new_user = models.User(email=user_data.email, password_hash=hashed_password)
    db.add(new_user)
    await db.commit()
    return {"message": "User created successfully"}

@app.post("/auth/token")
async def login_for_access_token(form_data: OAuth2PasswordRequestForm = Depends(), db: AsyncSession = Depends(get_session)):
    result = await db.execute(select(models.User).where(models.User.email == form_data.username))
    user = result.scalars().first()
    if not user or not auth.verify_password(form_data.password, user.password_hash):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    access_token = auth.create_access_token(data={"sub": user.email})
    return {"access_token": access_token, "token_type": "bearer"}

@app.get("/polls", response_model=List[schemas.Poll])
async def get_polls(db: AsyncSession = Depends(get_session), current_user: models.User = Depends(auth.get_current_user)):
    result = await db.execute(
        select(models.Poll)
        .where(models.Poll.instructor_id == current_user.id)
        .options(selectinload(models.Poll.questions).selectinload(models.Question.options))
    )
    polls = result.scalars().all()
    return polls

@app.get("/polls/{poll_id}", response_model=schemas.Poll)
async def get_poll(
    poll_id: int,
    db: AsyncSession = Depends(get_session),
    current_user: models.User = Depends(auth.get_current_user)
):
    poll_result = await db.execute(
        select(models.Poll).where(
            models.Poll.id == poll_id,
            models.Poll.instructor_id == current_user.id
        ).options(selectinload(models.Poll.questions).selectinload(models.Question.options))
    )
    poll = poll_result.scalars().first()
    if not poll:
        raise HTTPException(status_code=404, detail="Poll not found or not owned by user")
    return poll

@app.post("/polls/create", response_model=schemas.PollCreateResponse)
async def create_poll(poll_data: schemas.PollCreate, db: AsyncSession = Depends(get_session), current_user: models.User = Depends(auth.get_current_user)):
    access_code = ''.join(random.choices(string.ascii_uppercase + string.digits, k=6))
    
    new_poll = models.Poll(
        title=poll_data.title,
        instructor_id=current_user.id,
        access_code=access_code,
        description=poll_data.description
    )
    db.add(new_poll)
    await db.flush()

    for i, q_data in enumerate(poll_data.questions):
        new_question = models.Question(
            poll_id=new_poll.id,
            text=q_data.text,
            type=q_data.type,
            order=i
        )
        db.add(new_question)
        await db.flush()

        if q_data.options:
            for option_text in q_data.options:
                new_option = models.Option(
                    question_id=new_question.id,
                    text=option_text
                )
                db.add(new_option)
    
    await db.commit()
    await db.refresh(new_poll)

    return {"poll_id": new_poll.id, "access_code": new_poll.access_code}

@app.patch("/polls/{poll_id}/active", response_model=schemas.Poll)
async def update_poll_active_status(
    poll_id: int,
    status_update: schemas.PollStatusUpdate,
    db: AsyncSession = Depends(get_session),
    current_user: models.User = Depends(auth.get_current_user)
):
    poll_result = await db.execute(
        select(models.Poll).where(
            models.Poll.id == poll_id,
            models.Poll.instructor_id == current_user.id
        ).options(selectinload(models.Poll.questions).selectinload(models.Question.options))
    )
    poll = poll_result.scalars().first()

    if not poll:
        raise HTTPException(status_code=404, detail="Poll not found")

    poll.is_active = status_update.is_active
    db.add(poll)
    await db.commit()
    await db.refresh(poll)
    return poll

@app.put("/polls/{poll_id}/question/{question_id}", response_model=schemas.Question)
async def update_question(
    poll_id: int,
    question_id: int,
    question_data: schemas.QuestionCreate,
    db: AsyncSession = Depends(get_session),
    current_user: models.User = Depends(auth.get_current_user)
):
    # Verify poll exists and belongs to the current user
    poll_result = await db.execute(
        select(models.Poll).where(
            models.Poll.id == poll_id,
            models.Poll.instructor_id == current_user.id
        )
    )
    poll = poll_result.scalars().first()
    if not poll:
        raise HTTPException(status_code=404, detail="Poll not found or not owned by user")

    # Verify question exists and belongs to the specified poll
    question_result = await db.execute(
        select(models.Question).where(
            models.Question.id == question_id,
            models.Question.poll_id == poll_id
        )
    )
    question = question_result.scalars().first()
    if not question:
        raise HTTPException(status_code=404, detail="Question not found in this poll")

    # Update question fields
    question.text = question_data.text
    question.type = question_data.type
    
    # Delete existing options for this question
    await db.execute(models.Option.__table__.delete().where(models.Option.question_id == question.id))
    
    if question_data.options:
        for option_text in question_data.options:
            new_option = models.Option(question_id=question.id, text=option_text)
            db.add(new_option)

    db.add(question)
    await db.commit()
    await db.refresh(question)
    
    # Reload question with new options for response model
    await db.refresh(question, attribute_names=["options"]) 
    return schemas.Question.from_orm(question)

@app.delete("/polls/{poll_id}/question/{question_id}", status_code=204)
async def delete_question(
    poll_id: int,
    question_id: int,
    db: AsyncSession = Depends(get_session),
    current_user: models.User = Depends(auth.get_current_user)
):
    # Verify poll exists and belongs to the current user
    poll_result = await db.execute(
        select(models.Poll).where(
            models.Poll.id == poll_id,
            models.Poll.instructor_id == current_user.id
        )
    )
    poll = poll_result.scalars().first()
    if not poll:
        raise HTTPException(status_code=404, detail="Poll not found or not owned by user")

    # Verify question exists and belongs to the specified poll
    question_result = await db.execute(
        select(models.Question).where(
            models.Question.id == question_id,
            models.Question.poll_id == poll_id
        )
    )
    question = question_result.scalars().first()
    if not question:
        raise HTTPException(status_code=404, detail="Question not found in this poll")

    await db.delete(question)
    await db.commit()
    return {"message": "Question deleted successfully"}

@app.post("/polls/{poll_id}/question", response_model=schemas.Question)
async def add_question_to_poll(
    poll_id: int,
    question_data: schemas.QuestionCreate,
    db: AsyncSession = Depends(get_session),
    current_user: models.User = Depends(auth.get_current_user)
):
    # Verify poll exists and belongs to the current user
    poll_result = await db.execute(
        select(models.Poll).where(
            models.Poll.id == poll_id,
            models.Poll.instructor_id == current_user.id
        ).options(selectinload(models.Poll.questions))
    )
    poll = poll_result.scalars().first()
    if not poll:
        raise HTTPException(status_code=404, detail="Poll not found or not owned by user")

    # Determine the order for the new question
    new_order = len(poll.questions)

    # Create new question
    new_question = models.Question(
        poll_id=poll_id,
        text=question_data.text,
        type=question_data.type,
        order=new_order
    )
    db.add(new_question)
    await db.flush() # Flush to get the new_question.id

    if question_data.options:
        for option_text in question_data.options:
            new_option = models.Option(question_id=new_question.id, text=option_text)
            db.add(new_option)

    await db.commit()
    await db.refresh(new_question)
    
    await db.refresh(new_question, attribute_names=["options"])
    return schemas.Question.from_orm(new_question)

@app.post("/polls/{access_code}/vote")
async def submit_vote(access_code: str, vote: schemas.VoteCreate, db: AsyncSession = Depends(get_session)):
    result = await db.execute(select(models.Poll).where(models.Poll.access_code == access_code))
    poll = result.scalars().first()
    if not poll or not poll.is_active:
        raise HTTPException(status_code=404, detail="Poll not found or is not active")

    # Ensure the question belongs to the poll
    question_result = await db.execute(
        select(models.Question).where(models.Question.id == vote.question_id)
    )
    question = question_result.scalars().first()
    if not question or question.poll_id != poll.id:
        raise HTTPException(status_code=404, detail="Question not found in this poll")

    new_vote = models.Vote(
        question_id=vote.question_id,
        response_value=vote.response_value
    )
    db.add(new_vote)
    await db.commit()

    # --- Tally Calculation Logic ---
    tally_data = {}
    if question.type in (models.QuestionType.RATING, models.QuestionType.MULTIPLE_CHOICE):
        tally_query = (
            select(models.Vote.response_value, func.count(models.Vote.id))
            .where(models.Vote.question_id == vote.question_id)
            .group_by(models.Vote.response_value)
        )
        tally_result = await db.execute(tally_query)
        results = {value: count for value, count in tally_result.all()}
        tally_data = {
            "question_id": vote.question_id,
            "type": question.type.name,
            "results": results,
        }
    elif question.type == models.QuestionType.OPEN_ENDED:
        responses_query = select(models.Vote.response_value).where(models.Vote.question_id == vote.question_id)
        responses_result = await db.execute(responses_query)
        results = responses_result.scalars().all()
        tally_data = {
            "question_id": vote.question_id,
            "type": question.type.name,
            "results": results,
        }
    
    # Broadcast the updated tally to the instructor's room
    await manager.broadcast(str(poll.id), json.dumps({
        "type": "tally_update",
        "data": tally_data
    }))

    return {"message": "Vote submitted successfully"}


@app.websocket("/ws/polls/{poll_id}/instructor")
async def websocket_endpoint(websocket: WebSocket, poll_id: str, db: AsyncSession = Depends(get_session)):
    await manager.connect(websocket, poll_id)
    try:
        # --- Start of new initial state logic ---
        
        # 1. Get the full poll details
        poll_result = await db.execute(
            select(models.Poll)
            .where(models.Poll.id == int(poll_id))
            .options(selectinload(models.Poll.questions).selectinload(models.Question.options))
        )
        poll = poll_result.scalars().first()

        if not poll:
            await websocket.close(code=status.WS_1008_POLICY_VIOLATION)
            return

        # 2. Calculate initial tally for all questions
        initial_tally = []
        for question in poll.questions:
            tally_data = {}
            if question.type in (models.QuestionType.RATING, models.QuestionType.MULTIPLE_CHOICE):
                tally_query = (
                    select(models.Vote.response_value, func.count(models.Vote.id))
                    .where(models.Vote.question_id == question.id)
                    .group_by(models.Vote.response_value)
                )
                tally_result = await db.execute(tally_query)
                results = {value: count for value, count in tally_result.all()}
                tally_data = {
                    "question_id": question.id,
                    "type": question.type.name,
                    "results": results,
                }
            elif question.type == models.QuestionType.OPEN_ENDED:
                responses_query = select(models.Vote.response_value).where(models.Vote.question_id == question.id)
                responses_result = await db.execute(responses_query)
                results = responses_result.scalars().all()
                tally_data = {
                    "question_id": question.id,
                    "type": question.type.name,
                    "results": results,
                }
            initial_tally.append(tally_data)

        # 3. Send the initial state to the client
        # Note: Pydantic's from_orm is now dict() in v2, but we need to ensure compatibility.
        # A manual dict conversion is safer if Pydantic version is uncertain.
        poll_dict = {
            "id": poll.id,
            "title": poll.title,
            "description": poll.description,
            "access_code": poll.access_code,
            "is_active": poll.is_active,
            "questions": [
                {
                    "id": q.id,
                    "text": q.text,
                    "type": q.type.name,
                    "order": q.order,
                    "options": [{"id": o.id, "text": o.text} for o in q.options]
                } for q in poll.questions
            ]
        }

        await websocket.send_text(json.dumps({
            "type": "initial_state",
            "data": {
                "poll": poll_dict,
                "tallies": initial_tally
            }
        }))
        
        # --- End of new initial state logic ---

        while True:
            data = await websocket.receive_text()
            if data == "ping":
                await websocket.send_text("pong")
            # Here you would handle other instructor commands
    except WebSocketDisconnect:
        manager.disconnect(websocket, poll_id)
    except Exception:
        # Ensure connection is closed on error
        manager.disconnect(websocket, poll_id)
