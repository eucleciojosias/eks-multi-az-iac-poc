import uuid

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models import Movie
from app.schemas import MovieCreate, MovieUpdate


async def get_movie(db: AsyncSession, movie_id: uuid.UUID) -> Movie | None:
    return await db.get(Movie, movie_id)


async def get_movies(db: AsyncSession, skip: int = 0, limit: int = 20) -> tuple[list[Movie], int]:
    total = await db.scalar(select(func.count()).select_from(Movie))
    result = await db.execute(
        select(Movie).order_by(Movie.created_at.desc()).offset(skip).limit(limit)
    )
    return list(result.scalars().all()), total or 0


async def create_movie(db: AsyncSession, data: MovieCreate) -> Movie:
    movie = Movie(**data.model_dump())
    db.add(movie)
    await db.commit()
    await db.refresh(movie)
    return movie


async def update_movie(db: AsyncSession, movie_id: uuid.UUID, data: MovieUpdate) -> Movie | None:
    movie = await db.get(Movie, movie_id)
    if movie is None:
        return None
    for field, value in data.model_dump().items():
        setattr(movie, field, value)
    await db.commit()
    await db.refresh(movie)
    return movie


async def delete_movie(db: AsyncSession, movie_id: uuid.UUID) -> bool:
    movie = await db.get(Movie, movie_id)
    if movie is None:
        return False
    await db.delete(movie)
    await db.commit()
    return True
