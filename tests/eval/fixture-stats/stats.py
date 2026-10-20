"""Small statistics helpers used by the stats command line tool."""
import sys


def mean(xs):
    return sum(xs) / len(xs)


def median(xs):
    s = sorted(xs)
    return s[len(s) // 2]


def main(argv):
    if len(argv) < 2:
        print("usage: stats.py mean|median <numbers...>")
        return 2
    cmd, nums = argv[0], [float(a) for a in argv[1:]]
    if cmd == "mean":
        print(mean(nums))
    elif cmd == "median":
        print(median(nums))
    else:
        print("usage: stats.py mean|median <numbers...>")
        return 2
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
