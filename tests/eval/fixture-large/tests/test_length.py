import unittest

from units import length


class LengthTest(unittest.TestCase):
    def test_round_trip(self):
        self.assertAlmostEqual(length.from_base(length.to_base(2.5, "km"), "km"), 2.5)
