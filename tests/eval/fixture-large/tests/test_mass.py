import unittest

from units import mass


class MassTest(unittest.TestCase):
    def test_round_trip(self):
        self.assertAlmostEqual(mass.from_base(mass.to_base(2.5, "kg"), "kg"), 2.5)

    def test_pound(self):
        self.assertAlmostEqual(mass.to_base(1, "pound"), 453.59237)
