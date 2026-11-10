"""convert VALUE FROM TO KIND, e.g. convert.py 3 mile km length"""
import importlib
import sys


def convert(value, src, dst, kind):
    mod = importlib.import_module("units." + kind)
    return mod.from_base(mod.to_base(value, src), dst)


if __name__ == "__main__":
    v, src, dst, kind = sys.argv[1:5]
    print(round(convert(float(v), src, dst, kind), 6))
