
import requests
import json

BASE_URL = "http://127.0.0.1:8000"

def create_test_poll():
    # 1. Register/Login as Instructor
    email = "instructor@example.com"
    password = "password123"
    
    # Register (ignore error if exists)
    requests.post(f"{BASE_URL}/auth/register", json={"email": email, "password": password})
    
    # Login
    login_res = requests.post(f"{BASE_URL}/auth/token", data={"username": email, "password": password})
    if login_res.status_code != 200:
        print(f"Login failed: {login_res.text}")
        return
    token = login_res.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}
    
    # 2. Create Poll
    poll_data = {
        "title": "Flutter Web Test Poll",
        "description": "Testing the student client flow.",
        "questions": [
            {
                "text": "How do you like Flutter?",
                "type": "RATING", 
                "options": []
            },
            {
                "text": "What is your favorite framework?",
                "type": "MULTIPLE_CHOICE",
                "options": ["Flutter", "React", "Vue"]
            },
            {
                "text": "Any feedback?",
                "type": "OPEN_ENDED",
                "options": []
            }
        ]
    }
    
    create_res = requests.post(f"{BASE_URL}/polls/create", json=poll_data, headers=headers)
    if create_res.status_code == 200:
        data = create_res.json()
        print(f"SUCCESS: Poll Created!")
        print(f"Poll ID: {data['poll_id']}")
        print(f"Access Code: {data['access_code']}")
        
        # Activate it
        requests.patch(f"{BASE_URL}/polls/{data['poll_id']}/active", json={"is_active": True}, headers=headers)
        print("Poll Activated.")
        return data['access_code']
    else:
        print(f"Failed to create poll: {create_res.text}")

if __name__ == "__main__":
    create_test_poll()
