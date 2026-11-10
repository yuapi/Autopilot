"""Area units, in square meters."""

FACTORS = {
    "hectare": 10000,
    "acre": 4046.8564224,
    "sqft": 0.09290304,
    "sqkm": 1000000,
}


def to_base(value, unit):
    """Convert value in unit to square meters."""
    return value * FACTORS[unit]


def from_base(value, unit):
    """Convert value in square meters to unit."""
    return value / FACTORS[unit]
