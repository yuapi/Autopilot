import unittest

from units import angle


class AngleTest(unittest.TestCase):
    def test_round_trip(self):
        self.assertAlmostEqual(angle.from_base(angle.to_base(2.5, "degree"), "degree"), 2.5)
