# Gemini Project Context: Dynamic Polling System

This document provides a comprehensive overview of the "Dynamic Polling" project.

## Project Architecture

This project is a real-time classroom feedback system with three distinct components:

1.  **Backend (The Core):** A FastAPI application acting as the central hub. It manages authentication, complex hybrid poll structures, and handles real-time WebSocket broadcasting.
2.  **Instructor App (Mobile):** A Flutter Mobile application (Android/iOS) for instructors to create hybrid polls (Rating, Multiple Choice, Open-Ended), generate QR codes, and view live analytics.
3.  **Student Client (Web):** A Flutter Web application (Browser-based). Students access this via a URL or QR code to submit anonymous responses without installing an app.

---

## 1. Backend Service

* **Framework:** FastAPI (Python)
* **Database:** PostgreSQL (SQLAlchemy / SQLModel)
* **Real-Time:** Native WebSockets (with `ConnectionManager` room support)
* **Security:** OAuth2 with JWT (JSON Web Tokens)

### Setup & Running
1.  **Environment:** Ensure a `.env` file is present with `DATABASE_URL` and `SECRET_KEY`.
2.  **Install dependencies:**
    ```bash
    pip install fastapi uvicorn sqlalchemy psycopg2-binary passlib[bcrypt] python-jose[cryptography] python-multipart
    ```
3.  **Run Server:**
    ```bash
    uvicorn app.main:app --reload 
    ```

### Key Modules
* `auth.py`: Handles password hashing and JWT token generation.
* `websocket_manager.py`: Manages "Rooms" based on `poll_id` to ensure votes are broadcast only to the correct instructor.
* `models.py`: Defines the "Hybrid Poll" schema (Polymorphic questions: Rating vs Multi-Choice).

---

## 2. Instructor App (Mobile)

* **Platform:** Flutter (Mobile)
* **State Management:** Provider / Riverpod (depending on implementation)
* **Key Packages:**
    * `fl_chart`: For real-time bar charts and visualization.
    * `qr_flutter`: For generating the connection QR code.
    * `flutter_secure_storage`: For storing JWT tokens securely.
    * `http` / `dio`: For REST API calls.

### Setup & Running
1.  **Install dependencies:**
    ```bash
    flutter pub get
    ```
2.  **Run on Device:**
    ```bash
    flutter run
    ```

### Features
* **Authentication:** Login/Signup with persistent JWT storage.
* **Dashboard:** List of active/past polls.
* **Create Poll Wizard:** Supports adding multiple question types (1-5 Rating, Multiple Choice, Open Ended) in a single session.
* **Live Session:** Connects to `ws://{server}/ws/polls/{id}/instructor` to receive real-time updates.

---

## 3. Student Client (Web)

* **Platform:** Flutter Web
* **Accessibility:** No login required (Anonymous Guest Access).

### Setup & Running
1.  **Enable Web Support:**
    ```bash
    flutter config --enable-web
    ```
2.  **Run in Browser:**
    ```bash
    flutter run -d chrome --web-port=3000
    ```

### Features
* **Join Flow:** Parses URL parameters (e.g., `app.com/join/{access_code}`) to enter the session immediately.
* **Polling Interface:** Renders different widgets based on the Question Type (Star slider for ratings, Buttons for multiple choice).
* **Feedback:** Sends data to `POST /polls/vote` and receives "Vote Received" confirmation.