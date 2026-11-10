import unittest

from units import time


class TimeTest(unittest.TestCase):
    def test_round_trip(self):
        self.assertAlmostEqual(time.from_base(time.to_base(2.5, "minute"), "minute"), 2.5)
