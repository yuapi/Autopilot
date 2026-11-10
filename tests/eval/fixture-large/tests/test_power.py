import unittest

from units import power


class PowerTest(unittest.TestCase):
    def test_round_trip(self):
        self.assertAlmostEqual(power.from_base(power.to_base(2.5, "kw"), "kw"), 2.5)
