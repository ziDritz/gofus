import json
import os
from pathlib import Path
from typing import Dict, List
import xml.etree.ElementTree as ET

def extract_bounds_from_xml(xml_file: Path) -> Dict[str, Dict[str, float]]:
    """Extract bounds from a single XML file."""
    print(f"Processing file: {xml_file.name}")
    tree = ET.parse(xml_file)
    root = tree.getroot()
    bounds_data = {}

    for item in root.findall('.//item[@type="DefineSpriteTag"]'):
        bounds_elem = item.find('bounds')
        if bounds_elem is not None:
            horizontal = float(bounds_elem.get('horizontal', 0))
            vertical = float(bounds_elem.get('vertical', 0))
            print(f"  Found bounds: horizontal={horizontal}, vertical={vertical}")

            sprite_id = item.get('spriteId')
            print(f"  Sprite ID: {sprite_id}")

            for export_tag in root.findall('.//item[@type="ExportAssetsTag"]'):
                tags = export_tag.find('tags')
                names = export_tag.find('names')
                if tags is not None and names is not None:
                    tag_items = tags.findall('item')
                    name_items = names.findall('item')
                    for tag, name in zip(tag_items, name_items):
                        if tag.text == sprite_id:
                            bounds_data[name.text] = {
                                "horizontal": horizontal,
                                "vertical": vertical
                            }
                            print(f"  Matched name: {name.text}")
    return bounds_data

def process_xml_folder(folder_path: Path, output_path: Path) -> None:
    """Process all XML files in a folder and export bounds to JSON."""
    all_bounds = {}

    for xml_file in folder_path.glob('*.xml'):
        print(f"\nExtracting from: {xml_file.name}")
        bounds_data = extract_bounds_from_xml(xml_file)
        all_bounds.update(bounds_data)
        print(f"  Current bounds data: {bounds_data}")

    with open(output_path, 'w', encoding='utf-8') as f:
        json.dump(all_bounds, f, indent=2)

    print(f"\nBounds exported to: {output_path.name}")

if __name__ == "__main__":
    import sys

    if len(sys.argv) != 3:
        print("Usage: python script.py <xml_folder_path> <output_json_path>")
        sys.exit(1)

    xml_folder = Path(sys.argv[1])
    output_json = Path(sys.argv[2])

    if not xml_folder.is_dir():
        print(f"Error: {xml_folder} is not a valid directory.")
        sys.exit(1)

    process_xml_folder(xml_folder, output_json)
