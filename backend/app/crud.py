from sqlalchemy.orm import Session
from . import models, schemas

def get_instructor_by_email(db: Session, email: str):
    return db.query(models.Instructor).filter(models.Instructor.email == email).first()

def create_poll(db: Session, poll: schemas.PollCreate, instructor_id: int) -> models.Poll:
    with db.begin():
        db_poll = models.Poll(
            title=poll.title,
            description=poll.description,
            instructor_id=instructor_id
        )
        db.add(db_poll)
        db.flush()  # Use flush to get the poll ID before commit

        for question_data in poll.questions:
            db_question = models.Question(
                poll_id=db_poll.id,
                question_text=question_data.text,
                question_type=question_data.type,
                order_index=question_data.order
            )
            db.add(db_question)
            db.flush()  # Use flush to get the question ID

            if question_data.options:
                for option_text in question_data.options:
                    db_option = models.Option(
                        question_id=db_question.id,
                        option_text=option_text
                    )
                    db.add(db_option)
        
        db.commit()
        db.refresh(db_poll)
        return db_poll

def get_poll(db: Session, poll_id: int):
    return db.query(models.Poll).filter(models.Poll.id == poll_id).first()
