from __future__ import annotations

import logging

from app.providers.base import CandleData, MarketDataProvider, ProviderResponseError, QuoteData

logger = logging.getLogger(__name__)


class FallbackMarketDataProvider:
    name = "auto"

    def __init__(self, providers: list[MarketDataProvider]) -> None:
        self._providers = providers

    async def get_quote(self, symbol: str, market: str) -> QuoteData:
        errors: list[str] = []
        for provider in self._providers:
            try:
                return await provider.get_quote(symbol, market)
            except Exception as exc:
                logger.warning("Quote provider %s failed: %s", provider.name, exc)
                errors.append(f"{provider.name}: {exc}")

        raise ProviderResponseError("; ".join(errors))

    async def get_daily_candles(self, symbol: str, market: str, limit: int) -> list[CandleData]:
        errors: list[str] = []
        for provider in self._providers:
            try:
                return await provider.get_daily_candles(symbol, market, limit)
            except Exception as exc:
                logger.warning("Candle provider %s failed: %s", provider.name, exc)
                errors.append(f"{provider.name}: {exc}")

        raise ProviderResponseError("; ".join(errors))
