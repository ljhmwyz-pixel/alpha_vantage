# Backend

FastAPI backend for market data, watchlists, and alerts.

## Providers

Set `MARKET_DATA_PROVIDER`:

- `auto`: tries `yfinance`, then `yahoo_chart`, then `mock`.
- `mock`: deterministic local data for UI and API development.
- `yfinance`: real market data through the open-source yfinance client.
- `yahoo_chart`: real market data through Yahoo's public chart endpoint.
- `alpha_vantage`: Alpha Vantage HTTP API. Requires `ALPHA_VANTAGE_API_KEY`.

Provider code lives in `app/providers`. API routes should call `MarketDataService`, not providers directly.

## API

- `GET /api/v1/health`
- `GET /api/v1/market/quotes/{symbol}?market=US`
- `GET /api/v1/market/quotes/{symbol}/candles?market=US&limit=60`
- `GET /api/v1/watchlist`
- `POST /api/v1/watchlist`
- `DELETE /api/v1/watchlist/{item_id}`
- `GET /api/v1/alerts`
- `POST /api/v1/alerts`
- `DELETE /api/v1/alerts/{alert_id}`

Current auth is a development boundary using `X-User-Id`. Replace it with real JWT/OAuth before public release.
