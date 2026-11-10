"""Data units, in bytes."""

FACTORS = {
    "kb": 1000,
    "mb": 1000000,
    "gb": 1000000000,
    "kib": 1024,
    "mib": 1048576,
}


def to_base(value, unit):
    """Convert value in unit to bytes."""
    return value * FACTORS[unit]


def from_base(value, unit):
    """Convert value in bytes to unit."""
    return value / FACTORS[unit]
