from fastapi import APIRouter

from .routes import router as spec_router

router = APIRouter()
router.include_router(spec_router, prefix="/spec", tags=["spec"])
