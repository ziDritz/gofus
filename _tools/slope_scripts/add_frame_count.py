#!/usr/bin/env python3
# Usage: python3 add_frame_count.py input.json output.json

import json
import sys

def add_frame_count(input_file, output_file):
    try:
        with open(input_file, 'r') as f:
            data = json.load(f)
    except FileNotFoundError:
        print(f"Error: Input file '{input_file}' not found.")
        return
    except json.JSONDecodeError:
        print(f"Error: Invalid JSON in '{input_file}'.")
        return

    total_entries = len(data)
    updated_count = 0

    for i, (key, entry) in enumerate(data.items(), 1):
        if "frame_count" not in entry:
            entry["frame_count"] = 1
            updated_count += 1
        print(f"Processed {i}/{total_entries} entries", end='\r')

    print(f"\nUpdated {updated_count}/{total_entries} entries.")

    with open(output_file, 'w') as f:
        json.dump(data, f, indent=2)

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python3 add_frame_count.py input.json output.json")
        sys.exit(1)

    input_file = sys.argv[1]
    output_file = sys.argv[2]
    add_frame_count(input_file, output_file)
