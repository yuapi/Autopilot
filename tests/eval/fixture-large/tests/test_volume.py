import unittest

from units import volume


class VolumeTest(unittest.TestCase):
    def test_round_trip(self):
        self.assertAlmostEqual(volume.from_base(volume.to_base(2.5, "ml"), "ml"), 2.5)
