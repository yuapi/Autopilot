import unittest

from units import speed


class SpeedTest(unittest.TestCase):
    def test_round_trip(self):
        self.assertAlmostEqual(speed.from_base(speed.to_base(2.5, "kmh"), "kmh"), 2.5)
