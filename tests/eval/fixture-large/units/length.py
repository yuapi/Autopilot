"""Length units, in meters."""

FACTORS = {
    "km": 1000,
    "cm": 0.01,
    "mm": 0.001,
    "mile": 1609.344,
    "yard": 0.9144,
    "foot": 0.3048,
    "inch": 0.0254,
}


def to_base(value, unit):
    """Convert value in unit to meters."""
    return value * FACTORS[unit]


def from_base(value, unit):
    """Convert value in meters to unit."""
    return value / FACTORS[unit]
