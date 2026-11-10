"""Angle units, in radians."""

FACTORS = {
    "degree": 0.017453292519943295,
    "turn": 6.283185307179586,
    "grad": 0.015707963267948967,
}


def to_base(value, unit):
    """Convert value in unit to radians."""
    return value * FACTORS[unit]


def from_base(value, unit):
    """Convert value in radians to unit."""
    return value / FACTORS[unit]
