import json
import os
import tempfile
import unittest

import todo


class TodoTest(unittest.TestCase):
    def setUp(self):
        fd, self.db = tempfile.mkstemp(suffix=".json")
        os.close(fd)
        os.remove(self.db)
        todo.DB = self.db

    def tearDown(self):
        if os.path.exists(self.db):
            os.remove(self.db)

    def items(self):
        with open(self.db) as f:
            return json.load(f)

    def test_add_appends(self):
        todo.add("milk")
        todo.add("bread")
        self.assertEqual([i["text"] for i in self.items()], ["milk", "bread"])

    def test_done_marks_the_numbered_item(self):
        todo.add("first")
        todo.add("second")
        todo.done(1)  # numbers shown by `list` start at 1
        self.assertEqual([i["done"] for i in self.items()], [True, False])


if __name__ == "__main__":
    unittest.main()
