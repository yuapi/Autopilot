import unittest

from units import area


class AreaTest(unittest.TestCase):
    def test_round_trip(self):
        self.assertAlmostEqual(area.from_base(area.to_base(2.5, "hectare"), "hectare"), 2.5)
