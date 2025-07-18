from pydantic_settings import BaseSettings

from dotenv import load_dotenv
import os

# Load .env file (optional, good for local dev)
load_dotenv()

class Settings(BaseSettings):
    HUGGINGFACE_API_KEY: str
    

    class Config:
        env_file = ".env"

# Create a settings instance you can reuse
settings = Settings()
