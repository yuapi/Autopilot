"""Speed units, in meters per second."""

FACTORS = {
    "kmh": 0.2777777777777778,
    "mph": 0.44704,
    "knot": 0.514444,
}


def to_base(value, unit):
    """Convert value in unit to meters per second."""
    return value * FACTORS[unit]


def from_base(value, unit):
    """Convert value in meters per second to unit."""
    return value / FACTORS[unit]
