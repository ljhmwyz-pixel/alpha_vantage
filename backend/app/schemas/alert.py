from __future__ import annotations

from datetime import datetime
from typing import Literal

from pydantic import BaseModel, ConfigDict, Field

AlertRuleType = Literal[
    "price_above",
    "price_below",
    "percent_change_above",
    "percent_change_below",
]


class AlertCreate(BaseModel):
    symbol: str = Field(min_length=1, max_length=32)
    market: str = Field(default="US", min_length=1, max_length=16)
    rule_type: AlertRuleType
    threshold: float


class AlertRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    user_id: str
    symbol: str
    market: str
    rule_type: str
    threshold: float
    is_active: bool
    last_triggered_at: datetime | None
    created_at: datetime
