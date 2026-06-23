"""Notification Integration Point.

Per the PDF (T-6.2): WhatsApp message cost is on the client. The system designs
a flexible Integration Point so the provider can be swapped later without
touching call sites. Routes call send_notification(...); the configured
provider handles delivery.
"""
from datetime import datetime
from typing import Optional
import json

from flask import current_app

from ..extensions import db
from ..models import NotificationLog


def send_notification(
    school_id: int, kind: str, payload: dict,
    target_phone: Optional[str] = None, target_email: Optional[str] = None,
    related_kind: Optional[str] = None, related_id: Optional[int] = None,
) -> NotificationLog:
    log = NotificationLog(
        school_id=school_id,
        kind=kind,
        payload=json.dumps(payload, ensure_ascii=False),
        target_phone=target_phone,
        target_email=target_email,
        related_kind=related_kind,
        related_id=related_id,
        status="queued",
    )
    db.session.add(log)
    db.session.flush()

    provider = current_app.config.get("WHATSAPP_PROVIDER", "stub")
    try:
        if provider == "stub":
            _send_stub(log)
        else:
            log.error = f"unknown provider: {provider}"
            log.status = "failed"
        log.attempts += 1
        log.last_attempt_at = datetime.utcnow()
    except Exception as e:  # noqa: BLE001
        log.status = "failed"
        log.error = str(e)[:255]
        log.attempts += 1
        log.last_attempt_at = datetime.utcnow()

    db.session.commit()
    return log


def _send_stub(log: NotificationLog) -> None:
    log.status = "sent"
    log.sent_at = datetime.utcnow()
