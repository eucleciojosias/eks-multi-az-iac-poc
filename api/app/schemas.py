import uuid
from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field


class MovieBase(BaseModel):
    name: str = Field(min_length=1, max_length=255)
    cast: list[str] = Field(default_factory=list)
    synopsis: str = ""


class MovieCreate(MovieBase):
    pass


class MovieUpdate(MovieBase):
    pass


class MovieOut(MovieBase):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    created_at: datetime
    updated_at: datetime


class MovieList(BaseModel):
    items: list[MovieOut]
    total: int
