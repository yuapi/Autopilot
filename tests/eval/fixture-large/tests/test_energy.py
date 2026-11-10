import unittest

from units import energy


class EnergyTest(unittest.TestCase):
    def test_round_trip(self):
        self.assertAlmostEqual(energy.from_base(energy.to_base(2.5, "kj"), "kj"), 2.5)
