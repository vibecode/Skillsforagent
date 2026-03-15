#!/usr/bin/env python3
"""
analyze_csv.py — Profile a CSV file and return schema + stats as JSON.

Usage:
    python3 analyze_csv.py --file data.csv [--encoding utf-8]
"""

import argparse
import json
import sys

import pandas as pd


def profile_column(series: pd.Series) -> dict:
    """Return profile info for a single column."""
    dtype_str = str(series.dtype)

    # Try to detect datetime
    if dtype_str == "object":
        try:
            pd.to_datetime(series.dropna().head(20))
            dtype_str = "datetime"
        except (ValueError, TypeError):
            dtype_str = "string"
    elif "int" in dtype_str:
        dtype_str = "int64"
    elif "float" in dtype_str:
        dtype_str = "float64"

    profile = {
        "name": series.name,
        "dtype": dtype_str,
        "nunique": int(series.nunique()),
        "nulls": int(series.isnull().sum()),
        "sample": series.dropna().head(5).tolist(),
    }

    if dtype_str in ("int64", "float64"):
        profile["min"] = float(series.min()) if not series.isnull().all() else None
        profile["max"] = float(series.max()) if not series.isnull().all() else None
        profile["mean"] = float(series.mean()) if not series.isnull().all() else None
        profile["median"] = float(series.median()) if not series.isnull().all() else None

    return profile


def main():
    parser = argparse.ArgumentParser(description="Profile a CSV file")
    parser.add_argument("--file", required=True, help="Path to CSV file")
    parser.add_argument("--encoding", default="utf-8", help="File encoding")
    args = parser.parse_args()

    try:
        df = pd.read_csv(args.file, encoding=args.encoding)
    except Exception as e:
        json.dump({"error": str(e)}, sys.stdout, indent=2)
        sys.exit(1)

    result = {
        "file": args.file,
        "row_count": len(df),
        "column_count": len(df.columns),
        "columns": [profile_column(df[col]) for col in df.columns],
        "memory_usage_bytes": int(df.memory_usage(deep=True).sum()),
    }

    # Summary stats for numeric columns
    numeric_desc = df.describe()
    if not numeric_desc.empty:
        result["summary_stats"] = json.loads(numeric_desc.to_json())

    json.dump(result, sys.stdout, indent=2, default=str)
    print()  # trailing newline


if __name__ == "__main__":
    main()
