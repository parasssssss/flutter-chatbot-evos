from pydantic import BaseModel


class SummariseRequest(BaseModel):
    text: str
    max_length: int = 100
    temperature: float = 0.3

class ChatRequest(BaseModel):
    message: str
    max_length: int = 200
    temperature: float = 0.7