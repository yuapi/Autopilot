"""Power units, in watts."""

FACTORS = {
    "kw": 1000,
    "hp": 745.699872,
    "mw": 1000000,
}


def to_base(value, unit):
    """Convert value in unit to watts."""
    return value * FACTORS[unit]


def from_base(value, unit):
    """Convert value in watts to unit."""
    return value / FACTORS[unit]
