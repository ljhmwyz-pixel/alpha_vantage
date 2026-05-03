from __future__ import annotations

from fastapi import APIRouter, HTTPException, status

from app.api.deps import CurrentUserId, DbSession
from app.schemas.alert import AlertCreate, AlertRead
from app.services.alert_service import AlertService

router = APIRouter(prefix="/alerts", tags=["alerts"])
service = AlertService()


@router.get("", response_model=list[AlertRead])
async def list_alerts(session: DbSession, user_id: CurrentUserId) -> list[AlertRead]:
    alerts = await service.list_alerts(session, user_id)
    return [AlertRead.model_validate(alert) for alert in alerts]


@router.post("", response_model=AlertRead, status_code=status.HTTP_201_CREATED)
async def create_alert(
    payload: AlertCreate,
    session: DbSession,
    user_id: CurrentUserId,
) -> AlertRead:
    alert = await service.create_alert(session, user_id, payload)
    return AlertRead.model_validate(alert)


@router.delete("/{alert_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_alert(alert_id: int, session: DbSession, user_id: CurrentUserId) -> None:
    deleted = await service.delete_alert(session, user_id, alert_id)
    if not deleted:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Alert not found.")
