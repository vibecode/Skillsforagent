#!/usr/bin/env python3
"""Validate that each draft summary is exactly 20 whitespace-delimited words.

Usage:
    check_summaries.py "Recipient - Subject - twenty word summary text here ..."
    check_summaries.py --file summaries.txt   # one "Recipient - Subject - summary" line per line
    echo "..." | check_summaries.py -

Each line must look like:
    Recipient - Subject - <summary>

Only the <summary> portion is word-counted. Subjects (and summaries) may
themselves contain " - ", so every separator after the first is treated as a
possible subject/summary boundary and a line passes when any parse yields an
exactly-20-word summary. Hyphenated terms (e.g. "well-known") count as a
single word because they contain no internal whitespace. Exits non-zero and
prints every failing line if any summary is not exactly 20 words.
"""
import sys
import argparse


def candidate_summaries(line):
    """Return every candidate <summary> for a '- Recipient - Subject - Summary'
    or 'Recipient - Subject - Summary' line. The recipient always ends at the
    first ' - '; each later ' - ' is a possible subject/summary boundary, so a
    subject containing ' - ' cannot force a miscount. Empty list = bad format."""
    text = line.strip()
    if text.startswith("- "):
        text = text[2:]
    first = text.split(" - ", 1)
    if len(first) != 2:
        return []
    parts = first[1].split(" - ")
    if len(parts) < 2:
        return []
    return [" - ".join(parts[i:]).strip() for i in range(1, len(parts))]


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
        candidates = candidate_summaries(line)
        if not candidates:
            failures.append((i, line, "does not match 'Recipient - Subject - Summary' format"))
            continue
        counts = [word_count(summary) for summary in candidates]
        if 20 not in counts:
            closest = min(counts, key=lambda n: abs(n - 20))
            failures.append((i, line, f"summary has {closest} words, expected exactly 20"))

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
