"""Volume units, in liters."""

FACTORS = {
    "ml": 0.001,
    "gallon": 3.785411784,
    "quart": 0.946352946,
    "pint": 0.473176473,
    "cup": 0.2365882365,
}


def to_base(value, unit):
    """Convert value in unit to liters."""
    return value * FACTORS[unit]


def from_base(value, unit):
    """Convert value in liters to unit."""
    return value / FACTORS[unit]
