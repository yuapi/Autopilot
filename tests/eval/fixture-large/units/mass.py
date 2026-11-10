"""Mass units, in grams."""

FACTORS = {
    "kg": 1000,
    "mg": 0.001,
    "pound": 4535.9237,
    "ounce": 28.349523125,
    "ton": 1000000,
}


def to_base(value, unit):
    """Convert value in unit to grams."""
    return value * FACTORS[unit]


def from_base(value, unit):
    """Convert value in grams to unit."""
    return value / FACTORS[unit]
