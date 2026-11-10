"""Pressure units, in pascals."""

FACTORS = {
    "kpa": 1000,
    "bar": 100000,
    "psi": 6894.757,
    "atm": 101325,
}


def to_base(value, unit):
    """Convert value in unit to pascals."""
    return value * FACTORS[unit]


def from_base(value, unit):
    """Convert value in pascals to unit."""
    return value / FACTORS[unit]
