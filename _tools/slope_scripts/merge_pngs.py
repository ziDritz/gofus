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
import logging
from PIL import Image


def setup_logging(main_folder):
    """
    Configure logging to write both to a file and the console.
    """
    log_path = os.path.join(main_folder, "spritesheet.log")

    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s [%(levelname)s] %(message)s",
        handlers=[
            logging.FileHandler(log_path, encoding="utf-8"),
            logging.StreamHandler(sys.stdout),
        ],
    )

    logging.info("Logging initialized")
    logging.info(f"Log file: {log_path}")


def is_two_number_folder(name):
    """
    Match folder names that contain exactly two numbers separated by an underscore.

    Examples:
        DefineSprite_1581_49  -> matches (1581, 49)
        DefineSprite_891      -> no match
    """
    return re.search(r'_(\d+)_(\d+)$', name)


def merge_pngs_horizontally(png_paths, output_path):
    """
    Merge multiple PNG images into a single horizontal spritesheet.
    """
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
    logging.info(f"Spritesheet created: {output_path}")


def main(main_folder):
    logging.info(f"Starting processing in: {main_folder}")

    metadata = {}

    for root, dirs, files in os.walk(main_folder):
        folder_name = os.path.basename(root)
        match = is_two_number_folder(folder_name)

        if not match:
            continue

        number_1, number_2 = match.groups()
        logging.info(f"Processing folder: {folder_name}")
        logging.info(f"Detected numbers: {number_1}, {number_2}")

        png_files = sorted(
            [os.path.join(root, f) for f in files if f.lower().endswith(".png")],
            key=lambda x: int(re.search(r'(\d+)\.png$', os.path.basename(x)).group(1))
        )

        png_count = len(png_files)
        logging.info(f"PNG count: {png_count}")

        if png_count <= 1:
            logging.warning("Skipping folder (not enough PNG files)")
            continue

        output_name = f"{number_2}.png"
        output_path = os.path.join(main_folder, output_name)

        logging.info("Merging PNG files")
        merge_pngs_horizontally(png_files, output_path)

        metadata[number_2] = {
            "frame_count": png_count
        }

    json_path = os.path.join(main_folder, "sprites_metadata.json")
    with open(json_path, "w", encoding="utf-8") as f:
        json.dump(metadata, f, indent=2)

    logging.info("Processing complete")
    logging.info(f"Metadata written to: {json_path}")


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Error: missing main folder argument")
        print("Usage: python build_spritesheets.py <main_folder>")
        sys.exit(1)

    main_folder = sys.argv[1]

    # Initialize logging before doing anything else
    setup_logging(main_folder)

    main(main_folder)
