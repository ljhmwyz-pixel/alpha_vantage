from __future__ import annotations

from datetime import datetime

from pydantic import BaseModel


class QuoteRead(BaseModel):
    symbol: str
    market: str
    price: float
    change: float
    change_percent: float
    currency: str
    as_of: datetime
    provider: str


class CandleRead(BaseModel):
    time: datetime
    open: float
    high: float
    low: float
    close: float
    volume: int
