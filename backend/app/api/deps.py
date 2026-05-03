from __future__ import annotations

from collections.abc import AsyncIterator
from functools import lru_cache
from typing import Annotated

from fastapi import Depends, Header
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import get_settings
from app.db.session import get_session
from app.providers.factory import create_market_data_provider
from app.services.market_data import MarketDataService


async def get_db() -> AsyncIterator[AsyncSession]:
    async for session in get_session():
        yield session


def get_current_user_id(x_user_id: Annotated[str | None, Header(alias="X-User-Id")] = None) -> str:
    return x_user_id or "demo-user"


@lru_cache
def get_market_data_service() -> MarketDataService:
    settings = get_settings()
    provider = create_market_data_provider(settings)
    return MarketDataService(provider, settings.quote_cache_ttl_seconds)


type DbSession = Annotated[AsyncSession, Depends(get_db)]
type CurrentUserId = Annotated[str, Depends(get_current_user_id)]
type MarketService = Annotated[MarketDataService, Depends(get_market_data_service)]
