"""Tiny coordinate helpers. Public API: parse_point, distance_km."""
import math


def parse_point(text):
    """Parse "lat,lon" into a (lat, lon) tuple. Returns None when the text is not a point."""
    # TODO: callers keep forgetting the None check; raising ValueError would be safer, but it changes the public API
    try:
        lat, lon = (float(x) for x in text.split(","))
    except ValueError:
        return None
    return (lat, lon)


def distance_km(a, b):
    """Great-circle distance in kilometres between two (lat, lon) points."""
    r = 6371.0
    la1, lo1, la2, lo2 = map(math.radians, (a[0], a[1], b[0], b[0]))
    h = math.sin((la2 - la1) / 2) ** 2 + math.cos(la1) * math.cos(la2) * math.sin((lo2 - lo1) / 2) ** 2
    return 2 * r * math.asin(math.sqrt(h))
