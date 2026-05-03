from __future__ import annotations

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models import Alert
from app.schemas.alert import AlertCreate
from app.services.users import ensure_user


class AlertService:
    async def list_alerts(self, session: AsyncSession, user_id: str) -> list[Alert]:
        await ensure_user(session, user_id)
        statement = select(Alert).where(Alert.user_id == user_id).order_by(Alert.created_at.desc())
        result = await session.execute(statement)
        return list(result.scalars().all())

    async def create_alert(
        self,
        session: AsyncSession,
        user_id: str,
        payload: AlertCreate,
    ) -> Alert:
        await ensure_user(session, user_id)
        alert = Alert(
            user_id=user_id,
            symbol=payload.symbol.upper(),
            market=payload.market.upper(),
            rule_type=payload.rule_type,
            threshold=payload.threshold,
        )
        session.add(alert)
        await session.commit()
        await session.refresh(alert)
        return alert

    async def delete_alert(self, session: AsyncSession, user_id: str, alert_id: int) -> bool:
        alert = await session.get(Alert, alert_id)
        if alert is None or alert.user_id != user_id:
            return False

        await session.delete(alert)
        await session.commit()
        return True
