import uuid

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from app import crud
from app.database import get_db
from app.schemas import MovieCreate, MovieList, MovieOut, MovieUpdate

router = APIRouter(prefix="/movies", tags=["movies"])


@router.post("", response_model=MovieOut, status_code=status.HTTP_201_CREATED)
async def create_movie(data: MovieCreate, db: AsyncSession = Depends(get_db)) -> MovieOut:
    return await crud.create_movie(db, data)


@router.get("", response_model=MovieList)
async def list_movies(
    skip: int = Query(0, ge=0),
    limit: int = Query(20, ge=1, le=100),
    db: AsyncSession = Depends(get_db),
) -> MovieList:
    items, total = await crud.get_movies(db, skip, limit)
    return MovieList(items=items, total=total)


@router.get("/{movie_id}", response_model=MovieOut)
async def get_movie(movie_id: uuid.UUID, db: AsyncSession = Depends(get_db)) -> MovieOut:
    movie = await crud.get_movie(db, movie_id)
    if movie is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Movie not found")
    return movie


@router.put("/{movie_id}", response_model=MovieOut)
async def update_movie(
    movie_id: uuid.UUID, data: MovieUpdate, db: AsyncSession = Depends(get_db)
) -> MovieOut:
    movie = await crud.update_movie(db, movie_id, data)
    if movie is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Movie not found")
    return movie


@router.delete("/{movie_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_movie(movie_id: uuid.UUID, db: AsyncSession = Depends(get_db)) -> None:
    deleted = await crud.delete_movie(db, movie_id)
    if not deleted:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Movie not found")
