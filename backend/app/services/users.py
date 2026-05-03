from __future__ import annotations

from sqlalchemy.ext.asyncio import AsyncSession

from app.models import User


async def ensure_user(session: AsyncSession, user_id: str) -> User:
    user = await session.get(User, user_id)
    if user is not None:
        return user

    user = User(id=user_id)
    session.add(user)
    await session.flush()
    return user
