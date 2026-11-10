import unittest

from units import data


class DataTest(unittest.TestCase):
    def test_round_trip(self):
        self.assertAlmostEqual(data.from_base(data.to_base(2.5, "kb"), "kb"), 2.5)
