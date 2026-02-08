"""FastAPI entry. All routes use dependency injection and typed handlers."""
from fastapi import FastAPI

from app.api import router as api_router
from app.core import ApiResponse

app = FastAPI(title="Spec API", version="0.1.0")
app.include_router(api_router, prefix="/api")


@app.get("/health")
def health() -> dict[str, str]:
    """Health check. Return type required."""
    return {"status": "ok"}
