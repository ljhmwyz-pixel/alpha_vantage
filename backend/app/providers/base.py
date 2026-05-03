from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime
from typing import Protocol


class ProviderError(RuntimeError):
    pass


class ProviderConfigurationError(ProviderError):
    pass


class ProviderRateLimitError(ProviderError):
    pass


class ProviderResponseError(ProviderError):
    pass


@dataclass(frozen=True, slots=True)
class QuoteData:
    symbol: str
    market: str
    price: float
    change: float
    change_percent: float
    currency: str
    as_of: datetime
    provider: str


@dataclass(frozen=True, slots=True)
class CandleData:
    time: datetime
    open: float
    high: float
    low: float
    close: float
    volume: int


class MarketDataProvider(Protocol):
    name: str

    async def get_quote(self, symbol: str, market: str) -> QuoteData:
        raise NotImplementedError

    async def get_daily_candles(self, symbol: str, market: str, limit: int) -> list[CandleData]:
        raise NotImplementedError
