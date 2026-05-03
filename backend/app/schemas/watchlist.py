from __future__ import annotations

from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field


class WatchlistCreate(BaseModel):
    symbol: str = Field(min_length=1, max_length=32)
    market: str = Field(default="US", min_length=1, max_length=16)
    name: str | None = Field(default=None, max_length=128)


class WatchlistItemRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    user_id: str
    symbol: str
    market: str
    name: str | None
    created_at: datetime
