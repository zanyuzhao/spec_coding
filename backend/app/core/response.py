"""Unified API response format. No Any."""
from typing import Generic, TypeVar

from pydantic import BaseModel, Field

T = TypeVar("T")


class ApiResponse(BaseModel, Generic[T]):
    """All API responses MUST use this shape."""

    ok: bool = Field(..., description="Request succeeded")
    data: T | None = Field(None, description="Payload when ok=True")
    error: str | None = Field(None, description="Error message when ok=False")


def success(data: T) -> ApiResponse[T]:
    """Return successful response with typed data."""
    return ApiResponse(ok=True, data=data, error=None)


def fail(message: str) -> ApiResponse[None]:
    """Return error response."""
    return ApiResponse(ok=False, data=None, error=message)
