# main.py
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from huggingface_hub import InferenceClient
import os, logging, traceback
from .config import settings



app = FastAPI()
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], allow_methods=["*"], allow_headers=["*"],
)


HF_TOKEN = settings.HUGGINGFACE_API_KEY         
if not HF_TOKEN:
    raise RuntimeError("HF_TOKEN environment variable not set")


CHAT_MODEL_ID      = "Qwen/Qwen2.5-Coder-7B-Instruct"  
SUMMARISE_MODEL_ID = "facebook/bart-large-cnn"            


chat_client = InferenceClient(                 
    provider="featherless-ai",
    api_key=HF_TOKEN,
)
sum_client  = InferenceClient(                 
    provider="hf-inference",
    api_key=HF_TOKEN,
)


class ChatRequest(BaseModel):
    message: str
    max_length: int = 20000
    temperature: float = 0.7

class SummariseRequest(BaseModel):
    text: str
    max_length: int = 20000
    temperature: float = 0.3


@app.post("/chat")
async def chat(req: ChatRequest):
    try:
        response = chat_client.chat.completions.create(
            model=CHAT_MODEL_ID,
            messages=[{"role": "user", "content": req.message}],
            max_tokens=req.max_length,
            temperature=req.temperature,
        )
        reply = response.choices[0].message["content"].strip()
        return {"reply": reply}
    except Exception as e:
        logging.error("Chat HF call failed", exc_info=True)
        raise HTTPException(status_code=500, detail=f"AI Service Error: {e}")


@app.post("/summarise")
async def summarise(req: SummariseRequest):
    try:
        result = sum_client.summarization(
            req.text,
            model=SUMMARISE_MODEL_ID,
        )
    
        summary = result.summary_text if hasattr(result, "summary_text") else result
        return {"summary": summary.strip()}
    except Exception as e:
        logging.error("Summarise HF call failed", exc_info=True)
        raise HTTPException(status_code=500, detail=f"AI Service Error: {e}")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
