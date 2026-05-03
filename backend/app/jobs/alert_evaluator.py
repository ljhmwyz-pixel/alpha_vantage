from __future__ import annotations

from app.models import Alert
from app.providers.base import QuoteData


def is_alert_triggered(alert: Alert, quote: QuoteData) -> bool:
    if not alert.is_active:
        return False

    if alert.rule_type == "price_above":
        return quote.price >= alert.threshold
    if alert.rule_type == "price_below":
        return quote.price <= alert.threshold
    if alert.rule_type == "percent_change_above":
        return quote.change_percent >= alert.threshold
    if alert.rule_type == "percent_change_below":
        return quote.change_percent <= alert.threshold

    return False
