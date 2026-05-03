from __future__ import annotations

from datetime import UTC, datetime, timedelta

from app.providers.base import CandleData, QuoteData


class MockMarketDataProvider:
    name = "mock"

    async def get_quote(self, symbol: str, market: str) -> QuoteData:
        normalized = symbol.upper()
        score = sum(ord(char) for char in normalized)
        base_price = 20 + (score % 450)
        change = round(((score % 200) - 100) / 100, 2)
        price = round(base_price + change, 2)
        change_percent = round((change / max(base_price, 1)) * 100, 2)

        return QuoteData(
            symbol=normalized,
            market=market.upper(),
            price=price,
            change=change,
            change_percent=change_percent,
            currency="USD",
            as_of=datetime.now(UTC),
            provider=self.name,
        )

    async def get_daily_candles(self, symbol: str, market: str, limit: int) -> list[CandleData]:
        quote = await self.get_quote(symbol, market)
        today = datetime.now(UTC).replace(hour=0, minute=0, second=0, microsecond=0)
        candles: list[CandleData] = []

        for index in range(max(limit, 1)):
            day = today - timedelta(days=limit - index - 1)
            drift = (index - limit / 2) * 0.35
            close = round(max(1, quote.price + drift), 2)
            open_price = round(max(1, close - 0.4), 2)
            high = round(max(open_price, close) + 1.2, 2)
            low = round(max(0.5, min(open_price, close) - 1.0), 2)
            volume = 1_000_000 + (index * 17_321)

            candles.append(
                CandleData(
                    time=day,
                    open=open_price,
                    high=high,
                    low=low,
                    close=close,
                    volume=volume,
                )
            )

        return candles
