# Walkthrough - Dynamic Polling System

The "Run All" task has been initiated. The following services are starting up:

## Services

| Component | URL | Status |
|-----------|-----|--------|
| **Backend API** | [http://localhost:8000](http://localhost:8000) | Running (Background) |
| **API Docs** | [http://localhost:8000/docs](http://localhost:8000/docs) | Available |
| **Student Client** | [http://localhost:3000](http://localhost:3000) | Launching (Chrome) |
| **Instructor App** | [http://localhost:4000](http://localhost:4000) | Launching (Chrome) |

## New Features

- **Anonymous Voting**: Students can vote without logging in.
- **Unique Participant Counting**: The instructor dashboard counts unique students in a session (based on browser session), not just total votes.
- **Real-time Updates**: Instructor sees vote counts update instantly via WebSockets.

## Verification

1.  **Backend**: Visit [http://localhost:8000/docs](http://localhost:8000/docs) to see the Swagger UI.
2.  **Student Client**: A Chrome window should open pointing to `http://localhost:3000`.
3.  **Instructor App**: A Chrome window should open pointing to `http://localhost:4000`.

> [!NOTE]
> The Flutter applications may take a few minutes to compile and launch the first time. Please keep the terminal windows open (in background) and do not close the browser windows spawned by the tool.

## Troubleshooting

- If the browser windows do not open, check the artifacts or terminal output.
- Ensure ports 8000, 3000, and 4000 are free.
