import unittest

import geo


class GeoTest(unittest.TestCase):
    def test_parse_point(self):
        self.assertEqual(geo.parse_point("48.85,2.35"), (48.85, 2.35))
        self.assertIsNone(geo.parse_point("not a point"))

    def test_distance_paris_london(self):
        paris, london = (48.8566, 2.3522), (51.5074, -0.1278)
        self.assertAlmostEqual(geo.distance_km(paris, london), 343.5, delta=1.0)


if __name__ == "__main__":
    unittest.main()
