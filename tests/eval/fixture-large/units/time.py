"""Time units, in seconds."""

FACTORS = {
    "minute": 60,
    "hour": 3600,
    "day": 86400,
    "week": 604800,
    "ms": 0.001,
}


def to_base(value, unit):
    """Convert value in unit to seconds."""
    return value * FACTORS[unit]


def from_base(value, unit):
    """Convert value in seconds to unit."""
    return value / FACTORS[unit]
