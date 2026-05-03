from __future__ import annotations

import pytest

from app.providers.mock import MockMarketDataProvider
from app.services.market_data import MarketDataService


@pytest.mark.asyncio
async def test_mock_quote_has_expected_shape() -> None:
    provider = MockMarketDataProvider()
    quote = await provider.get_quote("aapl", "us")

    assert quote.symbol == "AAPL"
    assert quote.market == "US"
    assert quote.price > 0
    assert quote.provider == "mock"


@pytest.mark.asyncio
async def test_market_data_service_caches_quotes() -> None:
    provider = MockMarketDataProvider()
    service = MarketDataService(provider, quote_ttl_seconds=60)

    first = await service.get_quote("MSFT", "US")
    second = await service.get_quote("msft", "us")

    assert first is second
