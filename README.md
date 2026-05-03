# Alpha Vantage Monitor

Cross-platform stock monitoring app scaffold for iOS and Android with a FastAPI backend.

## Architecture

- `mobile/`: Flutter app for iOS and Android.
- `backend/`: FastAPI service that owns data-provider credentials, market-data caching, watchlists, alerts, and future push-notification workflows.
- `docker-compose.yml`: production-like local stack with API, PostgreSQL, and Redis.
- `.github/workflows/ci.yml`: backend and mobile CI checks.

The backend is the integration boundary. Mobile clients do not call Alpha Vantage, AKShare, Tushare, or other market-data services directly. This keeps API keys out of app binaries and gives the backend one place to handle caching, rate limits, failover, and alert evaluation.

## Current Scope

This scaffold includes:

- FastAPI app with health, quotes, watchlist, and alert endpoints.
- Market-data provider abstraction with yfinance, mock, and Alpha Vantage implementations.
- SQLAlchemy models and Alembic migration baseline.
- Flutter app source with routing, theme, watchlist screen, stock detail screen, alerts, and settings.
- Docker and CI foundations.

## Local Backend

Install Python 3.12+ first.

```powershell
cd backend
python -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install --upgrade pip
python -m pip install -e ".[dev]"
copy ..\.env.example .env
alembic upgrade head
uvicorn app.main:app --reload
```

The API will run at `http://127.0.0.1:8000`.

## Local Mobile App

Install Flutter SDK first. Then generate the native platform shell once:

```powershell
cd mobile
flutter create . --project-name alpha_vantage_monitor --org com.example.alpha_vantage --platforms android,ios
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1
```

For a physical Android device such as OnePlus 13, replace `10.0.2.2` with your computer LAN IP address.

Building iOS requires macOS and Xcode.

## Docker Stack

```powershell
copy .env.example .env
docker compose up --build
```

The backend container uses PostgreSQL from Docker Compose by default.

## Environment

See `.env.example`. Keep secrets only in local `.env`, CI secrets, or your production secret manager.

## Production Readiness Checklist

- Replace demo `X-User-Id` authentication with JWT/OAuth before public launch.
- Move quote cache and alert scheduling to Redis-backed workers before high-volume monitoring.
- Configure Firebase Cloud Messaging and APNs for push delivery.
- Add app signing, privacy policy, crash reporting, analytics, and store metadata before release.
- Validate market-data licensing for the target use case and region.
