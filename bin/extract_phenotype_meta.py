#!/usr/bin/env python3

import sys
import math

MISSING_VALUES = {"", "NA", "NAN", "-9", "."}


def is_missing(value):
    if value is None:
        return True
    value = value.strip()
    if value == "":
        return True
    upper = value.upper()
    return upper in MISSING_VALUES


def parse_value(value):
    try:
        num = float(value)
    except ValueError:
        return None
    if math.isnan(num):
        return None
    # Normalize integers represented as floats
    if abs(num - round(num)) < 1e-8:
        return int(round(num))
    return num


def is_binary_values(values):
    if not values:
        return False
    return values.issubset({0, 1}) or values.issubset({1, 2})


def main():
    if len(sys.argv) < 3:
        sys.stderr.write(
            "Usage: extract_phenotype_meta.py <phenotype_file> <output_meta_file>\n"
        )
        sys.exit(1)

    phenotype_file = sys.argv[1]
    output_meta_file = sys.argv[2]

    with open(phenotype_file, "r", encoding="utf-8") as handle:
        header_line = handle.readline()
        if not header_line:
            sys.stderr.write(f"Empty phenotype file: {phenotype_file}\n")
            sys.exit(1)

        header_cols = header_line.strip().split()
        if len(header_cols) < 3:
            sys.stderr.write(
                "Phenotype file must have at least 3 columns: FID IID PHENOTYPE\n"
            )
            sys.exit(1)
        if len(header_cols) > 3:
            sys.stderr.write(
                "Phenotype file must contain exactly one phenotype column (FID IID + 1 phenotype).\n"
            )
            sys.exit(1)

        phenotype_name = header_cols[2]
        values = set()
        binary_ok = True

        for line in handle:
            line = line.strip()
            if not line:
                continue
            cols = line.split()
            if len(cols) < 3:
                continue
            raw = cols[2]
            if is_missing(raw):
                continue
            parsed = parse_value(raw)
            if parsed is None:
                binary_ok = False
                break
            if isinstance(parsed, float):
                binary_ok = False
                break
            if parsed not in (0, 1, 2):
                binary_ok = False
                break
            values.add(parsed)

        is_binary = binary_ok and is_binary_values(values)

    with open(output_meta_file, "w", encoding="utf-8") as out_handle:
        out_handle.write(f"{phenotype_name}\t{str(is_binary).lower()}\n")


if __name__ == "__main__":
    main()
