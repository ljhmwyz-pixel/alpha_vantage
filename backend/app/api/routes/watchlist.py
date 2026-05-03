from __future__ import annotations

from fastapi import APIRouter, HTTPException, status

from app.api.deps import CurrentUserId, DbSession
from app.schemas.watchlist import WatchlistCreate, WatchlistItemRead
from app.services.watchlist_service import WatchlistService

router = APIRouter(prefix="/watchlist", tags=["watchlist"])
service = WatchlistService()


@router.get("", response_model=list[WatchlistItemRead])
async def list_watchlist(session: DbSession, user_id: CurrentUserId) -> list[WatchlistItemRead]:
    items = await service.list_items(session, user_id)
    return [WatchlistItemRead.model_validate(item) for item in items]


@router.post("", response_model=WatchlistItemRead, status_code=status.HTTP_201_CREATED)
async def add_watchlist_item(
    payload: WatchlistCreate,
    session: DbSession,
    user_id: CurrentUserId,
) -> WatchlistItemRead:
    item = await service.add_item(session, user_id, payload)
    return WatchlistItemRead.model_validate(item)


@router.delete("/{item_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_watchlist_item(item_id: int, session: DbSession, user_id: CurrentUserId) -> None:
    deleted = await service.delete_item(session, user_id, item_id)
    if not deleted:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Watchlist item not found.",
        )
