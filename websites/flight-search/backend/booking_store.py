"""In-memory user/payment database and booking storage."""

from __future__ import annotations

import uuid
from datetime import datetime

# Pre-defined cardholders with payment methods (keyed by lowercase name)
CARDHOLDERS: dict[str, list[dict]] = {
    "john smith": [
        {"card_number": "4111111111111111", "expiry": "12/27", "cvv": "123", "type": "Visa"},
        {"card_number": "5500000000000004", "expiry": "06/28", "cvv": "456", "type": "Mastercard"},
    ],
    "jane doe": [
        {"card_number": "340000000000009", "expiry": "03/27", "cvv": "7890", "type": "Amex"},
    ],
    "bob wilson": [
        {"card_number": "4012888888881881", "expiry": "09/26", "cvv": "321", "type": "Visa"},
    ],
}

GENERIC_ERROR = "Payment failed. Please check your card details and try again."

# Confirmed bookings stored in memory
_bookings: list[dict] = []


def _normalize_expiry(expiry: str) -> str:
    """Normalize expiry to MM/YY format. Accepts '1227' or '12/27'."""
    raw = expiry.replace("/", "").replace("-", "").strip()
    if len(raw) == 4 and raw.isdigit():
        return f"{raw[:2]}/{raw[2:]}"
    return expiry


def validate_payment(cardholder_name: str, card_number: str, expiry: str, cvv: str) -> tuple[bool, str, str | None]:
    """Validate payment against stored cardholder data.

    Returns (success, error_message, card_type).
    """
    cards = CARDHOLDERS.get(cardholder_name.strip().lower())
    if not cards:
        return False, GENERIC_ERROR, None

    normalized_expiry = _normalize_expiry(expiry)

    for card in cards:
        if (
            card["card_number"] == card_number
            and card["expiry"] == normalized_expiry
            and card["cvv"] == cvv
        ):
            return True, "", card["type"]

    return False, GENERIC_ERROR, None


def create_booking(booking_data: dict) -> dict:
    """Store a confirmed booking and return it with a unique ID."""
    booking = {
        "booking_id": f"BK-{uuid.uuid4().hex[:8].upper()}",
        "status": "confirmed",
        "booked_at": datetime.utcnow().isoformat(),
        **booking_data,
    }
    _bookings.append(booking)
    return booking


def get_all_bookings() -> list[dict]:
    """Return all confirmed bookings."""
    return list(_bookings)
