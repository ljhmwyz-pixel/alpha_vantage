from __future__ import annotations

from datetime import UTC, datetime
from typing import Any

import httpx

from app.providers.base import (
    CandleData,
    ProviderConfigurationError,
    ProviderRateLimitError,
    ProviderResponseError,
    QuoteData,
)


class AlphaVantageProvider:
    name = "alpha_vantage"
    base_url = "https://www.alphavantage.co/query"

    def __init__(self, api_key: str | None) -> None:
        if not api_key:
            raise ProviderConfigurationError("ALPHA_VANTAGE_API_KEY is required.")
        self._api_key = api_key

    async def get_quote(self, symbol: str, market: str) -> QuoteData:
        payload = await self._request(
            {
                "function": "GLOBAL_QUOTE",
                "symbol": symbol.upper(),
                "apikey": self._api_key,
            }
        )
        quote = payload.get("Global Quote")
        if not isinstance(quote, dict) or not quote:
            raise ProviderResponseError("Alpha Vantage did not return a quote.")

        latest_trading_day = str(quote.get("07. latest trading day", ""))
        as_of = _parse_market_date(latest_trading_day)

        return QuoteData(
            symbol=str(quote.get("01. symbol", symbol)).upper(),
            market=market.upper(),
            price=_read_float(quote, "05. price"),
            change=_read_float(quote, "09. change"),
            change_percent=_read_percent(quote, "10. change percent"),
            currency="USD",
            as_of=as_of,
            provider=self.name,
        )

    async def get_daily_candles(self, symbol: str, market: str, limit: int) -> list[CandleData]:
        payload = await self._request(
            {
                "function": "TIME_SERIES_DAILY_ADJUSTED",
                "symbol": symbol.upper(),
                "outputsize": "compact",
                "apikey": self._api_key,
            }
        )
        series = payload.get("Time Series (Daily)")
        if not isinstance(series, dict) or not series:
            raise ProviderResponseError("Alpha Vantage did not return daily candles.")

        candles: list[CandleData] = []
        for day, values in sorted(series.items(), reverse=True)[:limit]:
            if not isinstance(values, dict):
                continue
            candles.append(
                CandleData(
                    time=_parse_market_date(day),
                    open=_read_float(values, "1. open"),
                    high=_read_float(values, "2. high"),
                    low=_read_float(values, "3. low"),
                    close=_read_float(values, "4. close"),
                    volume=int(float(str(values.get("6. volume", "0")))),
                )
            )

        return sorted(candles, key=lambda candle: candle.time)

    async def _request(self, params: dict[str, str]) -> dict[str, Any]:
        async with httpx.AsyncClient(timeout=10.0) as client:
            response = await client.get(self.base_url, params=params)
            response.raise_for_status()
            payload = response.json()

        if not isinstance(payload, dict):
            raise ProviderResponseError("Alpha Vantage returned an unexpected payload.")
        if "Note" in payload or "Information" in payload:
            message = str(payload.get("Note") or payload.get("Information"))
            raise ProviderRateLimitError(message)
        if "Error Message" in payload:
            raise ProviderResponseError(str(payload["Error Message"]))

        return payload


def _parse_market_date(value: str) -> datetime:
    if not value:
        return datetime.now(UTC)
    return datetime.fromisoformat(value).replace(tzinfo=UTC)


def _read_float(payload: dict[str, Any], key: str) -> float:
    value = payload.get(key)
    if value is None:
        raise ProviderResponseError(f"Missing field: {key}")
    return float(str(value))


def _read_percent(payload: dict[str, Any], key: str) -> float:
    value = payload.get(key)
    if value is None:
        raise ProviderResponseError(f"Missing field: {key}")
    return float(str(value).replace("%", ""))
