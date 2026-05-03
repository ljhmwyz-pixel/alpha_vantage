from __future__ import annotations

from datetime import UTC, datetime
from typing import Any, cast
from urllib.parse import quote

import httpx

from app.providers.base import CandleData, ProviderResponseError, QuoteData


class YahooChartProvider:
    name = "yahoo_chart"
    base_url = "https://query1.finance.yahoo.com/v8/finance/chart"

    async def get_quote(self, symbol: str, market: str) -> QuoteData:
        yahoo_symbol = _to_yahoo_symbol(symbol.upper(), market.upper())
        result = await self._request(yahoo_symbol, range_value="5d", interval="1d")
        meta = result["meta"]
        timestamps = result.get("timestamp", [])
        quote = result["indicators"]["quote"][0]
        closes = _valid_points(timestamps, quote.get("close", []))

        if not closes:
            raise ProviderResponseError(f"No quote data returned for {symbol}.")

        price = float(meta.get("regularMarketPrice") or closes[-1][1])
        previous = float(meta.get("previousClose") or (closes[-2][1] if len(closes) > 1 else price))
        change = round(price - previous, 4)
        change_percent = round((change / previous) * 100, 4) if previous else 0.0
        as_of_timestamp = int(meta.get("regularMarketTime") or closes[-1][0])

        return QuoteData(
            symbol=symbol.upper(),
            market=market.upper(),
            price=round(price, 4),
            change=change,
            change_percent=change_percent,
            currency=str(meta.get("currency") or "USD"),
            as_of=datetime.fromtimestamp(as_of_timestamp, UTC),
            provider=self.name,
        )

    async def get_daily_candles(self, symbol: str, market: str, limit: int) -> list[CandleData]:
        yahoo_symbol = _to_yahoo_symbol(symbol.upper(), market.upper())
        result = await self._request(yahoo_symbol, range_value="6mo", interval="1d")
        timestamps = result.get("timestamp", [])
        quote = result["indicators"]["quote"][0]

        candles: list[CandleData] = []
        for index, timestamp in enumerate(timestamps):
            values = {
                "open": _read_index(quote.get("open", []), index),
                "high": _read_index(quote.get("high", []), index),
                "low": _read_index(quote.get("low", []), index),
                "close": _read_index(quote.get("close", []), index),
                "volume": _read_index(quote.get("volume", []), index),
            }
            if any(values[key] is None for key in ("open", "high", "low", "close")):
                continue

            candles.append(
                CandleData(
                    time=datetime.fromtimestamp(int(timestamp), UTC),
                    open=round(float(values["open"]), 4),
                    high=round(float(values["high"]), 4),
                    low=round(float(values["low"]), 4),
                    close=round(float(values["close"]), 4),
                    volume=int(values["volume"] or 0),
                )
            )

        if not candles:
            raise ProviderResponseError(f"No candle data returned for {symbol}.")
        return candles[-limit:]

    async def _request(self, symbol: str, range_value: str, interval: str) -> dict[str, Any]:
        async with httpx.AsyncClient(timeout=12.0) as client:
            response = await client.get(
                f"{self.base_url}/{quote(symbol)}",
                params={"range": range_value, "interval": interval},
            )
            response.raise_for_status()
            payload = response.json()

        chart = payload.get("chart", {})
        if chart.get("error"):
            raise ProviderResponseError(str(chart["error"]))

        results = chart.get("result") or []
        if not results:
            raise ProviderResponseError(f"No Yahoo chart result for {symbol}.")

        return cast(dict[str, Any], results[0])


def _valid_points(timestamps: list[Any], values: list[Any]) -> list[tuple[int, float]]:
    points: list[tuple[int, float]] = []
    for timestamp, value in zip(timestamps, values, strict=False):
        if value is not None:
            points.append((int(timestamp), float(value)))
    return points


def _read_index(values: list[Any], index: int) -> Any:
    if index >= len(values):
        return None
    return values[index]


def _to_yahoo_symbol(symbol: str, market: str) -> str:
    if "." in symbol:
        return symbol
    if market == "HK":
        return f"{symbol.zfill(4)}.HK" if symbol.isdigit() else f"{symbol}.HK"
    if market in {"SH", "SSE"}:
        return f"{symbol}.SS"
    if market in {"SZ", "SZSE"}:
        return f"{symbol}.SZ"
    return symbol
