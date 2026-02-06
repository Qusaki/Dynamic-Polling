
import sys
import os

# Add current directory to path
sys.path.append(os.getcwd())

from app import models, schemas

def test_schema_missing_options():
    print("--- Starting Schema Serialization Test ---")
    
    # 1. Manually create a Question object (simulating a DB object)
    question = models.Question(
        id=1,
        poll_id=1,
        text="What is the capital of France?",
        type=models.QuestionType.MULTIPLE_CHOICE,
        order=0
    )
    
    # 2. Add options to the question
    # In a real DB fetch, SQLAlchemy populates this list. Here we simulate it.
    question.options = [
        models.Option(id=1, question_id=1, text="Paris"),
        models.Option(id=2, question_id=1, text="London"),
        models.Option(id=3, question_id=1, text="Berlin"),
    ]
    
    print(f"DEBUG: Question Object Options: {[o.text for o in question.options]}")
    
    # 3. Serialize using the Pydantic Schema
    # This is what FastAPI does before sending the JSON response
    try:
        pydantic_question = schemas.Question.from_orm(question)
        print(f"DEBUG: Serialized Pydantic Data: {pydantic_question.dict()}")
        
        # 4. Verify if 'options' exists in the output
        if hasattr(pydantic_question, 'options') and pydantic_question.options:
            print("SUCCESS: 'options' field is present and populated.")
        else:
            print("FAILURE: 'options' field is MISSING or empty in the Pydantic model.")
            print("       The frontend will receive a question with NO options.")
            
    except Exception as e:
        print(f"ERROR: {e}")

if __name__ == "__main__":
    test_schema_missing_options()
