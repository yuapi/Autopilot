import unittest

from units import pressure


class PressureTest(unittest.TestCase):
    def test_round_trip(self):
        self.assertAlmostEqual(pressure.from_base(pressure.to_base(2.5, "kpa"), "kpa"), 2.5)
