# Dynamic Polling System

A real-time classroom feedback system designed to facilitate interactive polling and immediate analysis of student responses. The system comprises a FastAPI backend, a Flutter mobile application for instructors, and a Flutter web client for students.

## Table of Contents
- [Project Architecture](#project-architecture)
  - [1. Backend Service (FastAPI)](#1-backend-service-fastapi)
  - [2. Instructor App (Flutter Mobile)](#2-instructor-app-flutter-mobile)
  - [3. Student Client (Flutter Web)](#3-student-client-flutter-web)
- [Features](#features)
- [Setup & Running](#setup--running)
  - [Backend](#backend)
  - [Instructor App](#instructor-app)
  - [Student Client](#student-client)
- [Service Ports](#service-ports)
- [Authentication](#authentication)
- [Real-Time Communication](#real-time-communication)
- [Database](#database)
- [Contributing](#contributing)
- [License](#license)

---

## Project Architecture

This project is a real-time classroom feedback system with three distinct components:

### 1. Backend Service (FastAPI)
The central hub built with FastAPI (Python), managing authentication, complex hybrid poll structures, and handling real-time WebSocket broadcasting.
The central hub built with FastAPI (Python), managing authentication, complex hybrid poll structures, and handling real-time WebSocket broadcasting.
- **Hosting:** Deployed on Render (`https://dynamic-polling.onrender.com`).
- **Framework:** FastAPI (Python)
- **Database:** PostgreSQL (SQLAlchemy / SQLModel)
- **Real-Time:** Native WebSockets (with `ConnectionManager` room support)
- **Security:** OAuth2 with JWT (JSON Web Tokens)

### 2. Instructor App (Flutter Mobile)
A Flutter mobile application (Android/iOS) for instructors to create hybrid polls (Rating, Multiple Choice, Open-Ended), generate QR codes, and view live analytics.
A Flutter mobile application (Android/iOS) for instructors to create hybrid polls (Rating, Multiple Choice, Open-Ended), generate QR codes, and view live analytics.
- **Platform:** Flutter (Mobile)
- **Performance:** Implements local caching (`shared_preferences`) for instant loading and optimistic UI updates to handle network latency.
- **UI:** Optimized for various screen sizes with `SafeArea` support and responsive padding.
- **Key Packages:** `fl_chart` for data visualization, `qr_flutter` for QR code generation, `flutter_secure_storage` for secure token storage, `shared_preferences` for caching.

### 3. Student Client (Flutter Web)
A Flutter web application (Browser-based) for students to submit anonymous responses. Students access this via a URL or QR code without needing to install an app.
- **Platform:** Flutter Web
- **Accessibility:** No login required (Anonymous Guest Access).

## Features
- **Authentication:** Secure user registration and login for instructors using OAuth2 and JWT.
- **Poll Creation:** Instructors can create dynamic hybrid polls with multiple question types (Rating, Multiple Choice, Open-Ended).
- **Question Management:** Edit, delete, and add questions to existing polls after creation.
- **Live Sessions:** Real-time display of poll results via WebSockets for instructors.
- **Poll Control:** Instructors can start/stop polls to control student voting.
- **Sharing:** Generate QR codes and shareable URLs for students to join polls.
- **Anonymous Voting:** Students can respond to polls anonymously via a web interface.
- **Dynamic Charts:** Real-time bar charts and response lists for various question types.

## Performance Optimizations
To ensure a smooth experience even on free-tier hosting (Render):
- **Local Caching:** Polls are cached locally using `shared_preferences`, allowing the app to load instantly even if the backend is cold.
- **Network Timeouts:** API requests have a 30s timeout to prevent infinite hanging.
- **Feedback Indicators:** The app detects slow server responses and informs the user if the server is waking up.

## Setup & Running

To get the Dynamic Polling System up and running, follow these steps:

### Backend

1.  **Prerequisites:** Ensure you have Python 3.10+ and `pip` installed.
2.  **Environment Variables:** Create a `.env` file in the `backend/` directory with the following content:
    ```
    DATABASE_URL="postgresql+asyncpg://user:password@host:port/database_name"
    SECRET_KEY="your_super_secret_key_for_jwt"
    ```
    *Replace `user`, `password`, `host`, `port`, `database_name` with your PostgreSQL database credentials.*
    *Replace `your_super_secret_key_for_jwt` with a strong, random string.*
3.  **Install dependencies:**
    ```bash
    cd backend
    pip install -r requirements.txt
    ```
4.  **Run Server:**
    ```bash
    uvicorn main:app --reload --host 0.0.0.0 --port 8000
    ```
    The backend API will be available at `http://localhost:8000`.

### Instructor App

1.  **Prerequisites:** Ensure you have the Flutter SDK installed and configured.
2.  **Install dependencies:**
    ```bash
    cd flutter_instructor_app
    flutter pub get
    ```
3.  **Run on Device/Emulator:**
    ```bash
    flutter run
    ```
    The instructor app will connect to the backend running at `http://10.0.2.2:8000` (for Android emulator) or `http://localhost:8000` (for iOS simulator/desktop).

4.  **Run in Browser:**
    ```bash
    flutter run -d chrome --web-port=4000
    ```
    The instructor app will be available at `http://localhost:4000`.

### Student Client

1.  **Prerequisites:** Ensure you have the Flutter SDK installed and web support enabled (`flutter config --enable-web`).
2.  **Install dependencies:**
    ```bash
    cd flutter_student_web
    flutter pub get
    ```
3.  **Run in Browser:**
    ```bash
    flutter run -d chrome --web-port=3000
    ```
    The student client will be available in your browser at `http://localhost:3000`.

## Service Ports

| Service | Port | URL |
|---------|------|-----|
| Backend API | 443 | https://dynamic-polling.onrender.com |
| Student Client | 3000 | http://localhost:3000 |
| Instructor App | 4000 | http://localhost:4000 |

## Authentication

The system uses OAuth2 with JSON Web Tokens (JWT) for instructor authentication. Tokens are securely stored using `flutter_secure_storage` on the mobile app.

## Real-Time Communication

WebSockets are utilized for real-time updates to instructor screens, allowing immediate visualization of poll results as students vote.

## Database

PostgreSQL is used as the primary database, with SQLAlchemy and SQLModel for ORM operations.

## Contributing

Contributions are welcome! Please feel free to open issues or submit pull requests.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.