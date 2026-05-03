from __future__ import annotations

from dataclasses import dataclass
from datetime import UTC, datetime, timedelta

from app.providers.base import CandleData, MarketDataProvider, QuoteData


@dataclass(slots=True)
class CachedQuote:
    value: QuoteData
    expires_at: datetime


class MarketDataService:
    def __init__(self, provider: MarketDataProvider, quote_ttl_seconds: int) -> None:
        self._provider = provider
        self._quote_ttl = timedelta(seconds=max(quote_ttl_seconds, 1))
        self._quote_cache: dict[tuple[str, str], CachedQuote] = {}

    async def get_quote(self, symbol: str, market: str) -> QuoteData:
        key = (symbol.upper(), market.upper())
        now = datetime.now(UTC)
        cached = self._quote_cache.get(key)
        if cached and cached.expires_at > now:
            return cached.value

        quote = await self._provider.get_quote(*key)
        self._quote_cache[key] = CachedQuote(value=quote, expires_at=now + self._quote_ttl)
        return quote

    async def get_daily_candles(self, symbol: str, market: str, limit: int) -> list[CandleData]:
        normalized_limit = max(1, min(limit, 100))
        return await self._provider.get_daily_candles(
            symbol.upper(),
            market.upper(),
            normalized_limit,
        )
