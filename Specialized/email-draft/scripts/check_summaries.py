#!/usr/bin/env python3
"""Validate that each draft summary is exactly 20 whitespace-delimited words.

Usage:
    check_summaries.py "Recipient - Subject - twenty word summary text here ..."
    check_summaries.py --file summaries.txt   # one "Recipient - Subject - summary" line per line
    echo "..." | check_summaries.py -

Each line must look like:
    Recipient - Subject - <summary>

Only the <summary> portion (everything after the second " - ") is word-counted.
Hyphenated terms (e.g. "well-known") count as a single word because they contain
no internal whitespace. Exits non-zero and prints every failing line if any
summary is not exactly 20 words.
"""
import sys
import argparse


def split_line(line):
    """Split a '- Recipient - Subject - Summary' or 'Recipient - Subject - Summary'
    line into (recipient, subject, summary) using the first two ' - ' separators."""
    text = line.strip()
    if text.startswith("- "):
        text = text[2:]
    parts = text.split(" - ", 2)
    if len(parts) != 3:
        return None
    return parts[0].strip(), parts[1].strip(), parts[2].strip()


def word_count(summary):
    return len(summary.split())


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("line", nargs="?", help="A single line to check, or '-' to read one line from stdin")
    parser.add_argument("--file", help="Path to a file with one 'Recipient - Subject - Summary' line per draft")
    args = parser.parse_args()

    lines = []
    if args.file:
        with open(args.file, "r", encoding="utf-8") as f:
            lines = [l for l in f.read().splitlines() if l.strip()]
    elif args.line == "-":
        lines = [l for l in sys.stdin.read().splitlines() if l.strip()]
    elif args.line:
        lines = [args.line]
    else:
        parser.print_help()
        sys.exit(2)

    failures = []
    for i, line in enumerate(lines, 1):
        parsed = split_line(line)
        if parsed is None:
            failures.append((i, line, "does not match 'Recipient - Subject - Summary' format"))
            continue
        recipient, subject, summary = parsed
        n = word_count(summary)
        if n != 20:
            failures.append((i, line, f"summary has {n} words, expected exactly 20"))

    if failures:
        print(f"FAIL: {len(failures)} of {len(lines)} line(s) invalid\n")
        for i, line, reason in failures:
            print(f"  line {i}: {reason}")
            print(f"    {line}")
        sys.exit(1)

    print(f"PASS: all {len(lines)} summary line(s) are exactly 20 words")
    sys.exit(0)


if __name__ == "__main__":
    main()
