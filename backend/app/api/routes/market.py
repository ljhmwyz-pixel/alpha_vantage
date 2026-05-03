from __future__ import annotations

from dataclasses import asdict
from typing import Annotated

from fastapi import APIRouter, HTTPException, Query, status

from app.api.deps import MarketService
from app.providers.base import ProviderError
from app.schemas.market import CandleRead, QuoteRead

router = APIRouter(prefix="/market", tags=["market"])
type MarketQuery = Annotated[str, Query(min_length=1, max_length=16)]
type LimitQuery = Annotated[int, Query(ge=1, le=100)]


@router.get("/quotes/{symbol}", response_model=QuoteRead)
async def read_quote(
    symbol: str,
    service: MarketService,
    market: MarketQuery = "US",
) -> QuoteRead:
    try:
        quote = await service.get_quote(symbol, market)
    except ProviderError as exc:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=str(exc),
        ) from exc

    return QuoteRead(**asdict(quote))


@router.get("/quotes/{symbol}/candles", response_model=list[CandleRead])
async def read_daily_candles(
    symbol: str,
    service: MarketService,
    market: MarketQuery = "US",
    limit: LimitQuery = 60,
) -> list[CandleRead]:
    try:
        candles = await service.get_daily_candles(symbol, market, limit)
    except ProviderError as exc:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=str(exc),
        ) from exc

    return [CandleRead(**asdict(candle)) for candle in candles]
