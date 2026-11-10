"""Energy units, in joules."""

FACTORS = {
    "kj": 1000,
    "cal": 4.184,
    "kcal": 4184,
    "wh": 3600,
    "kwh": 3600000,
}


def to_base(value, unit):
    """Convert value in unit to joules."""
    return value * FACTORS[unit]


def from_base(value, unit):
    """Convert value in joules to unit."""
    return value / FACTORS[unit]
