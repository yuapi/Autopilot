import unittest

import temp


class TempTest(unittest.TestCase):
    def test_c_to_f(self):
        self.assertEqual(temp.c_to_f(100), 212)

    def test_f_to_c(self):
        self.assertEqual(temp.f_to_c(212), 100)


if __name__ == "__main__":
    unittest.main()
