"""Spec-related endpoints. All handlers typed; no untyped functions."""
from fastapi import APIRouter, Depends

from app.core import ApiResponse, success
from app.core.deps import get_placeholder_dep

router = APIRouter()


@router.get("/list", response_model=ApiResponse[list[dict[str, str]]])
def list_specs(dep: str = Depends(get_placeholder_dep)) -> ApiResponse[list[dict[str, str]]]:
    """List active specs. Demonstrates dependency injection."""
    return success([{"id": "1", "title": "Example", "status": "active"}])
