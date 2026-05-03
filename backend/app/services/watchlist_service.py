from __future__ import annotations

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models import WatchlistItem
from app.schemas.watchlist import WatchlistCreate
from app.services.users import ensure_user


class WatchlistService:
    async def list_items(self, session: AsyncSession, user_id: str) -> list[WatchlistItem]:
        await ensure_user(session, user_id)
        statement = (
            select(WatchlistItem)
            .where(WatchlistItem.user_id == user_id)
            .order_by(WatchlistItem.created_at.desc())
        )
        result = await session.execute(statement)
        return list(result.scalars().all())

    async def add_item(
        self,
        session: AsyncSession,
        user_id: str,
        payload: WatchlistCreate,
    ) -> WatchlistItem:
        await ensure_user(session, user_id)
        symbol = payload.symbol.upper()
        market = payload.market.upper()
        statement = select(WatchlistItem).where(
            WatchlistItem.user_id == user_id,
            WatchlistItem.symbol == symbol,
            WatchlistItem.market == market,
        )
        existing = (await session.execute(statement)).scalar_one_or_none()
        if existing is not None:
            return existing

        item = WatchlistItem(
            user_id=user_id,
            symbol=symbol,
            market=market,
            name=payload.name,
        )
        session.add(item)
        await session.commit()
        await session.refresh(item)
        return item

    async def delete_item(self, session: AsyncSession, user_id: str, item_id: int) -> bool:
        item = await session.get(WatchlistItem, item_id)
        if item is None or item.user_id != user_id:
            return False

        await session.delete(item)
        await session.commit()
        return True
