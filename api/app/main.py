from contextlib import asynccontextmanager

from fastapi import FastAPI
from sqlalchemy import text

from app.config import settings
from app.database import Base, async_session_factory, engine
from app.routers.movies import router as movies_router


@asynccontextmanager
async def lifespan(app: FastAPI):
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    yield
    await engine.dispose()


app = FastAPI(title=settings.app_name, lifespan=lifespan)
app.include_router(movies_router)


@app.get("/healthz")
async def healthz() -> dict[str, str]:
    async with async_session_factory() as session:
        await session.execute(text("SELECT 1"))
    return {"status": "ok"}
