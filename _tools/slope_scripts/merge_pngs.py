#!/usr/bin/env python3
"""
Usage:
    python merge_pngs.py <main_folder>

Example:
    python merge_pngs.py ./main_folder
"""

import os
import re
import json
import sys
from PIL import Image

def is_two_number_folder(name):
    """
    Match folders that contain exactly two numbers, e.g. DefineSprite_1581_49
    """
    return re.search(r'(\d+).*?(\d+)', name)

def merge_pngs_horizontally(png_paths, output_path):
    images = [Image.open(p) for p in png_paths]

    widths, heights = zip(*(img.size for img in images))
    total_width = sum(widths)
    max_height = max(heights)

    spritesheet = Image.new("RGBA", (total_width, max_height))

    x_offset = 0
    for img in images:
        spritesheet.paste(img, (x_offset, 0))
        x_offset += img.width

    spritesheet.save(output_path)
    print(f"  ✔ Spritesheet created: {output_path}")

def main(main_folder):
    print(f"Starting processing in: {main_folder}")

    metadata = {}

    for root, dirs, files in os.walk(main_folder):
        folder_name = os.path.basename(root)
        match = is_two_number_folder(folder_name)

        if not match:
            continue

        number_1, number_2 = match.groups()
        print(f"\nProcessing folder: {folder_name}")
        print(f"  Detected numbers: {number_1}, {number_2}")

        png_files = sorted([
            os.path.join(root, f)
            for f in files
            if f.lower().endswith(".png")
        ])

        png_count = len(png_files)
        print(f"  PNG count: {png_count}")

        if png_count <= 1:
            print("  Skipping (not enough PNG files)")
            continue

        output_name = f"{number_2}.png"
        output_path = os.path.join(main_folder, output_name)

        print("  Merging PNG files...")
        merge_pngs_horizontally(png_files, output_path)

        metadata[number_2] = {
            "frame_count": png_count
        }

    json_path = os.path.join(main_folder, "sprites_metadata.json")
    with open(json_path, "w", encoding="utf-8") as f:
        json.dump(metadata, f, indent=2)

    print("\nAll done!")
    print(f"Metadata written to: {json_path}")

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Error: missing main folder argument")
        print("Usage: python build_spritesheets.py <main_folder>")
        sys.exit(1)

    main(sys.argv[1])
