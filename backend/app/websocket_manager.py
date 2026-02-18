from fastapi import WebSocket
from typing import Dict, List

class ConnectionManager:
    def __init__(self):
        self.active_connections: Dict[str, List[WebSocket]] = {}

    async def connect(self, websocket: WebSocket, poll_id: str):
        await websocket.accept()
        if poll_id not in self.active_connections:
            self.active_connections[poll_id] = []
        self.active_connections[poll_id].append(websocket)

    def disconnect(self, websocket: WebSocket, poll_id: str):
        if poll_id in self.active_connections:
            self.active_connections[poll_id].remove(websocket)
            if not self.active_connections[poll_id]:
                del self.active_connections[poll_id]

    async def broadcast(self, poll_id: str, message: str):
        if poll_id in self.active_connections:
            for connection in self.active_connections[poll_id]:
                await connection.send_text(message)
