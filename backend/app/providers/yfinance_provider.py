from __future__ import annotations

import asyncio
from datetime import UTC, datetime
from typing import Any, cast

import yfinance as yf

from app.providers.base import CandleData, ProviderResponseError, QuoteData


class YFinanceProvider:
    name = "yfinance"

    async def get_quote(self, symbol: str, market: str) -> QuoteData:
        return await asyncio.to_thread(self._get_quote, symbol.upper(), market.upper())

    async def get_daily_candles(self, symbol: str, market: str, limit: int) -> list[CandleData]:
        return await asyncio.to_thread(
            self._get_daily_candles,
            symbol.upper(),
            market.upper(),
            limit,
        )

    def _get_quote(self, symbol: str, market: str) -> QuoteData:
        yahoo_symbol = _to_yahoo_symbol(symbol, market)
        ticker = yf.Ticker(yahoo_symbol)
        history = ticker.history(period="5d", interval="1d", auto_adjust=False)
        if history.empty:
            raise ProviderResponseError(f"No quote data returned for {symbol}.")

        closes = history["Close"].dropna()
        if closes.empty:
            raise ProviderResponseError(f"No close price returned for {symbol}.")

        price = round(float(closes.iloc[-1]), 4)
        previous = float(closes.iloc[-2]) if len(closes) > 1 else price
        change = round(price - previous, 4)
        change_percent = round((change / previous) * 100, 4) if previous else 0.0
        as_of = _to_utc_datetime(closes.index[-1])

        currency = "USD"
        try:
            fast_info = getattr(ticker, "fast_info", {})
            currency = str(_read_mapping_value(fast_info, "currency") or currency)
        except Exception:
            currency = "USD"

        return QuoteData(
            symbol=symbol,
            market=market,
            price=price,
            change=change,
            change_percent=change_percent,
            currency=currency,
            as_of=as_of,
            provider=self.name,
        )

    def _get_daily_candles(self, symbol: str, market: str, limit: int) -> list[CandleData]:
        yahoo_symbol = _to_yahoo_symbol(symbol, market)
        history = yf.Ticker(yahoo_symbol).history(
            period="6mo",
            interval="1d",
            auto_adjust=False,
        )
        if history.empty:
            raise ProviderResponseError(f"No candle data returned for {symbol}.")

        candles: list[CandleData] = []
        for timestamp, row in history.tail(limit).iterrows():
            candles.append(
                CandleData(
                    time=_to_utc_datetime(timestamp),
                    open=round(float(row["Open"]), 4),
                    high=round(float(row["High"]), 4),
                    low=round(float(row["Low"]), 4),
                    close=round(float(row["Close"]), 4),
                    volume=int(row["Volume"]),
                )
            )

        return candles


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


def _to_utc_datetime(value: Any) -> datetime:
    if hasattr(value, "to_pydatetime"):
        converted = cast(datetime, value.to_pydatetime())
    elif isinstance(value, datetime):
        converted = value
    else:
        converted = datetime.fromisoformat(str(value))

    if converted.tzinfo is None:
        return converted.replace(tzinfo=UTC)
    return converted.astimezone(UTC)


def _read_mapping_value(mapping: Any, key: str) -> Any:
    if hasattr(mapping, "get"):
        return mapping.get(key)
    return None
