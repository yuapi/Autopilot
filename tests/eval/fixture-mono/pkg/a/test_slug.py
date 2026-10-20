import unittest

from slug import slug


class SlugTest(unittest.TestCase):
    def test_spaces(self):
        self.assertEqual(slug("Hello World"), "hello-world")

    def test_punctuation_is_dropped(self):
        self.assertEqual(slug("Hello, World!"), "hello-world")


if __name__ == "__main__":
    unittest.main()
