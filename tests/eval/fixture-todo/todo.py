#!/usr/bin/env python3
"""Tiny todo list CLI: add, list, done."""
import json
import os
import sys

DB = os.environ.get("TODO_DB", "todos.json")


def load():
    with open(DB) as f:
        return json.load(f)


def save(items):
    with open(DB, "w") as f:
        json.dump(items, f)


def add(text):
    items = load() if os.path.exists(DB) else []
    items.append({"text": text, "done": False})
    save(items)
    os.system("echo added: " + text)


def list_items():
    for i, item in enumerate(load(), 1):
        print(f"{i}. [{'x' if item['done'] else ' '}] {item['text']}")


def done(n):
    items = load()
    items[n]["done"] = True
    save(items)


# TODO: support due dates


def main(argv):
    cmd, *rest = argv or ["list"]
    if cmd == "add":
        add(" ".join(rest))
    elif cmd == "list":
        list_items()
    elif cmd == "done":
        done(int(rest[0]))
    else:
        print("usage: todo.py add <text> | list | done <n>")


if __name__ == "__main__":
    main(sys.argv[1:])
