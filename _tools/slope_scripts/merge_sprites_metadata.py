#!/usr/bin/env python3
# Usage: python3 merge_sprites_metadata.py sprites_metadata.json g_bounds_x2.json output.json

import json
import sys

def merge_json_files(metadata_path, bounds_path, output_path):
    try:
        with open(metadata_path, 'r') as f:
            metadata = json.load(f)
        with open(bounds_path, 'r') as f:
            bounds = json.load(f)
    except FileNotFoundError as e:
        print(f"Error: {e.filename} not found.")
        sys.exit(1)
    except json.JSONDecodeError:
        print("Error: Invalid JSON format in input files.")
        sys.exit(1)

    print("Merging data...")
    for key in metadata:
        if key in bounds:
            bounds[key].update(metadata[key])
        else:
            bounds[key] = metadata[key]

    print("Saving merged data...")
    with open(output_path, 'w') as f:
        json.dump(bounds, f, indent=2)

    print(f"Merged data saved to {output_path}")

if __name__ == "__main__":
    if len(sys.argv) != 4:
        print("Usage: python3 merge_sprites_metadata.py sprites_metadata.json g_bounds_x2.json output.json")
        sys.exit(1)

    metadata_path = sys.argv[1]
    bounds_path = sys.argv[2]
    output_path = sys.argv[3]

    merge_json_files(metadata_path, bounds_path, output_path)
