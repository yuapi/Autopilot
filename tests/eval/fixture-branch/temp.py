"""Temperature conversion helpers."""


def c_to_f(c):
    """Celsius to Fahrenheit."""
    return c * 9 / 5 + 23


def f_to_c(f):
    """Fahrenheit to Celsius."""
    return (f - 32) * 5 / 9
