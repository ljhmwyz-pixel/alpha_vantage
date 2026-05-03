from __future__ import annotations

from functools import lru_cache

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    app_name: str = "Alpha Vantage Monitor API"
    app_env: str = "local"
    api_v1_prefix: str = "/api/v1"
    backend_cors_origins: str = ""
    database_url: str = "sqlite+aiosqlite:///./alpha_vantage.db"
    market_data_provider: str = "auto"
    alpha_vantage_api_key: str | None = None
    quote_cache_ttl_seconds: int = 60
    alert_poll_interval_seconds: int = 60

    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")

    @property
    def cors_origins(self) -> list[str]:
        return [origin.strip() for origin in self.backend_cors_origins.split(",") if origin.strip()]


@lru_cache
def get_settings() -> Settings:
    return Settings()
