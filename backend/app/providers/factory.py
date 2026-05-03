from __future__ import annotations

from app.core.config import Settings
from app.providers.alpha_vantage import AlphaVantageProvider
from app.providers.base import MarketDataProvider, ProviderConfigurationError
from app.providers.fallback import FallbackMarketDataProvider
from app.providers.mock import MockMarketDataProvider
from app.providers.yahoo_chart import YahooChartProvider
from app.providers.yfinance_provider import YFinanceProvider


def create_market_data_provider(settings: Settings) -> MarketDataProvider:
    provider = settings.market_data_provider.lower().strip()

    if provider == "auto":
        return FallbackMarketDataProvider(
            [
                YFinanceProvider(),
                YahooChartProvider(),
                MockMarketDataProvider(),
            ]
        )
    if provider == "mock":
        return MockMarketDataProvider()
    if provider in {"yfinance", "yahoo", "yahoo_finance"}:
        return YFinanceProvider()
    if provider in {"yahoo_chart", "yahoochart"}:
        return YahooChartProvider()
    if provider in {"alpha_vantage", "alphavantage"}:
        return AlphaVantageProvider(settings.alpha_vantage_api_key)

    raise ProviderConfigurationError(f"Unsupported market data provider: {provider}")
