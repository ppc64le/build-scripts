"""
extract_licenses.py
-------------------
Standalone script that reads a ScanCode JSON output file and extracts
license information using the same logic as WheelProcessor.run_scancode().

Usage:
    python3 extract_licenses.py <scancode_output.json>

Arguments:
    scancode_output.json   Path to the ScanCode JSON file (--json-pp output).

Output (plain text to stdout):
    MIT, Apache-2.0, BSD-3-Clause
"""

import argparse
import json
import re
import sys


def extract_licenses(scancode_output: dict) -> str:
    """
    Parse a ScanCode JSON output dict and return a comma-separated string
    of sorted SPDX license identifiers.

    Args:
        scancode_output: Parsed JSON from ScanCode --json-pp output.

    Returns:
        str: Comma-separated SPDX licenses, e.g. "Apache-2.0, MIT, BSD-3-Clause"

    Raises:
        TypeError:    If scancode_output is not a dict.
        ValueError:   If the expected 'license_detections' key is missing entirely,
                      or if a detection entry has an unexpected type.
        RuntimeError: If an unexpected error occurs during processing.
    """
    if not isinstance(scancode_output, dict):
        raise TypeError(
            f"Expected a dict for scancode_output, got {type(scancode_output).__name__}."
        )

    if "license_detections" not in scancode_output:
        raise ValueError(
            "Invalid ScanCode JSON: missing required key 'license_detections'."
        )

    licenses: set = set()

    try:
        for detection in scancode_output.get("license_detections", []):
            if not isinstance(detection, dict):
                raise ValueError(
                    f"Each license detection must be a dict, got {type(detection).__name__}."
                )

            expression = detection.get("license_expression_spdx")
            if expression is None:
                continue

            if not isinstance(expression, str):
                raise ValueError(
                    f"'license_expression_spdx' must be a string, got {type(expression).__name__}."
                )

            if not expression.strip():
                continue

            split_lics = re.sub(r"[()]", "", expression).split(" AND ")

            for lic in split_lics:
                lic = lic.strip()
                if not lic:
                    continue

                if "LicenseRef-scancode" not in lic:
                    licenses.add(lic)

    except (TypeError, ValueError):
        raise
    except Exception as exc:
        raise RuntimeError(
            f"Unexpected error while processing license detections: {exc}"
        ) from exc

    return ", ".join(sorted(licenses))


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Extract licenses from a ScanCode JSON output file."
    )
    parser.add_argument(
        "scancode_json",
        help="Path to the ScanCode --json-pp output file.",
    )
    args = parser.parse_args()

    try:
        with open(args.scancode_json, "r", encoding="utf-8") as fh:
            scancode_output = json.load(fh)
    except FileNotFoundError:
        print(f"Error: file not found: {args.scancode_json}", file=sys.stderr)
        sys.exit(1)
    except PermissionError:
        print(f"Error: permission denied reading file: {args.scancode_json}", file=sys.stderr)
        sys.exit(1)
    except json.JSONDecodeError as exc:
        print(f"Error: failed to parse JSON: {exc}", file=sys.stderr)
        sys.exit(1)
    except OSError as exc:
        print(f"Error: could not open file: {exc}", file=sys.stderr)
        sys.exit(1)

    try:
        result = extract_licenses(scancode_output)
    except TypeError as exc:
        print(f"Error: invalid input type — {exc}", file=sys.stderr)
        sys.exit(1)
    except ValueError as exc:
        print(f"Error: invalid ScanCode JSON structure — {exc}", file=sys.stderr)
        sys.exit(1)
    except RuntimeError as exc:
        print(f"Error: processing failed — {exc}", file=sys.stderr)
        sys.exit(1)

    print(result)


if __name__ == "__main__":
    main()
