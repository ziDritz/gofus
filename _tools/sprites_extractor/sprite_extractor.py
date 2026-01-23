"""
Dofus SWF Sprite Extractor with Matrix Transformation
Extracts character animations from SWF files into Godot-ready PNG sequences.
Applies parent transformation matrix to child sprites for proper alignment.
"""
import subprocess
import xml.etree.ElementTree as ET
import os
import shutil
import tempfile
import json
from pathlib import Path
from typing import Dict, List, Optional
from dataclasses import dataclass

# =========================
# CONFIGURATION
# =========================

CONFIG = {
    # Paths
    "ffdec_path": r"C:\Users\Moi\Documents\jpexs-decompiler\dist\ffdec.jar",
    "input_folder": "extract_sprites_test_input",
    "output_folder": "extract_sprites_test_output",
    
    # Export settings
    "scale_percent": 2.0,  # Zoom level as decimal (2.0 = 200%)
    "export_json_only": False,  # True = only export bounds.json, skip PNG extraction
    
    # Behavior
    "error_mode": "skip_with_warning",  # or "fail_on_error"
    "overwrite_mode": "skip",  # "skip", "overwrite", or "prompt"
    "keep_temp_xml": False,  # True for debugging
    "debug_mode": True,  # Show detailed extraction info
    
    # Processing
    "process_single_file": "core.swf",  # Set to filename to process single file
}

# =========================
# DATA STRUCTURES
# =========================

@dataclass
class AnimationInfo:
    """Stores information about a single animation"""
    name: str
    container_id: int
    child_id: int
    matrix_scale_x: float
    matrix_scale_y: float
    parent_horizontal_bound: float
    parent_vertical_bound: float

# =========================
# UTILITY FUNCTIONS
# =========================

def get_temp_dir() -> Path:
    """Create and return temp directory for XML files"""
    temp_base = Path(tempfile.gettempdir()) / "gofus_extract"
    temp_base.mkdir(exist_ok=True)
    return temp_base

def run_ffdec_command(args: List[str]) -> bool:
    """Execute FFDEC command and return success status"""
    try:
        cmd = ["java", "-jar", CONFIG["ffdec_path"]] + args
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            timeout=60
        )
        return result.returncode == 0
    except subprocess.TimeoutExpired:
        print("  ⚠ FFDec command timed out")
        return False
    except Exception as e:
        print(f"  ⚠ FFDec error: {e}")
        return False

def log_error(swf_file: str, animation: str, error: str):
    """Log extraction errors to file"""
    log_file = Path("extraction_errors.log")
    with open(log_file, "a", encoding="utf-8") as f:
        from datetime import datetime
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        f.write(f"{timestamp} | {swf_file} | {animation} | {error}\n")

def round_value(value: float, decimals: int = 2) -> float:
    """Round float value to specified decimal places"""
    return round(value, decimals)

# =========================
# XML PARSING
# =========================

def parse_swf_xml(xml_path: Path) -> List[AnimationInfo]:
    """Parse SWF XML and extract animation information including matrix and bounds"""
    tree = ET.parse(xml_path)
    root = tree.getroot()
    
    # Step 1: Build name -> container_id mapping
    name_map: Dict[str, int] = {}
    for export_tag in root.findall(".//item[@type='ExportAssetsTag']"):
        tags = export_tag.find("tags")
        names = export_tag.find("names")
        if tags is not None and names is not None:
            tag_items = tags.findall("item")
            name_items = names.findall("item")
            for tag_item, name_item in zip(tag_items, name_items):
                container_id = int(tag_item.text)
                name = name_item.text
                name_map[name] = container_id
    
    # Step 2: For each container, extract matrix and bounds
    animations: List[AnimationInfo] = []
    
    for name, container_id in name_map.items():
        # Find the parent container DefineSpriteTag
        parent_sprite_tag = root.find(f".//item[@type='DefineSpriteTag'][@spriteId='{container_id}']")
        if parent_sprite_tag is None:
            continue
        
        # Find PlaceObject2Tag to get child sprite and matrix
        place_tag = parent_sprite_tag.find(".//item[@type='PlaceObject2Tag']")
        if place_tag is None:
            continue
        
        child_id = place_tag.get("characterId")
        if child_id is None:
            continue
        
        # Extract matrix scale values
        matrix_scale_x = 1.0
        matrix_scale_y = 1.0
        matrix = place_tag.find("matrix")
        if matrix is not None:
            scale_x_str = matrix.get("scaleX")
            scale_y_str = matrix.get("scaleY")
            if scale_x_str:
                matrix_scale_x = round_value(float(scale_x_str))
            if scale_y_str:
                matrix_scale_y = round_value(float(scale_y_str))
        
        # Extract bounds from PARENT container sprite
        parent_horizontal_bound = 0.0
        parent_vertical_bound = 0.0
        
        # Try to find bounds as child element
        bounds_element = parent_sprite_tag.find("bounds")
        if bounds_element is not None:
            horizontal_str = bounds_element.get("horizontal")
            vertical_str = bounds_element.get("vertical")
            if horizontal_str:
                parent_horizontal_bound = float(horizontal_str)
            if vertical_str:
                parent_vertical_bound = float(vertical_str)
        else:
            # Try to find bounds as attribute on the sprite tag itself
            horizontal_str = parent_sprite_tag.get("horizontal")
            vertical_str = parent_sprite_tag.get("vertical")
            if horizontal_str:
                parent_horizontal_bound = float(horizontal_str)
            if vertical_str:
                parent_vertical_bound = float(vertical_str)
        
        animations.append(AnimationInfo(
            name=name,
            container_id=container_id,
            child_id=int(child_id),
            matrix_scale_x=matrix_scale_x,
            matrix_scale_y=matrix_scale_y,
            parent_horizontal_bound=parent_horizontal_bound,
            parent_vertical_bound=parent_vertical_bound
        ))
    
    return animations

# =========================
# EXPORT FUNCTIONS
# =========================

def export_swf_to_xml(swf_path: Path, xml_path: Path) -> bool:
    """Export SWF structure to XML"""
    print(f"  Exporting XML structure...")
    args = ["-swf2xml", str(swf_path), str(xml_path)]
    return run_ffdec_command(args)

def export_bounds_to_json(animations: List[AnimationInfo], output_path: Path):
    """Export animation bounds to JSON file with config scaling applied"""
    bounds_data = {}
    config_scale = CONFIG["scale_percent"]
    
    for anim in animations:
        # Calculate final bounds: parent_bound * config_scale
        final_horizontal = round_value(
            anim.parent_horizontal_bound * config_scale
        )
        final_vertical = round_value(
            anim.parent_vertical_bound * config_scale
        )
        
        bounds_data[anim.name] = {
            "horizontal": final_horizontal,
            "vertical": final_vertical
        }
    
    with open(output_path, "w", encoding="utf-8") as f:
        json.dump(bounds_data, f, indent=2)
    
    print(f"  ✓ Bounds exported to: {output_path.name} (scaled by {config_scale}x)")

def apply_matrix_transform(image, matrix_scale_x: float, matrix_scale_y: float):
    """Apply matrix transformation to image"""
    from PIL import Image
    
    # Apply scale (resize if scale != 1.0)
    abs_scale_x = abs(matrix_scale_x)
    abs_scale_y = abs(matrix_scale_y)
    
    if abs_scale_x != 1.0 or abs_scale_y != 1.0:
        new_width = int(image.width * abs_scale_x)
        new_height = int(image.height * abs_scale_y)
        if new_width > 0 and new_height > 0:
            image = image.resize((new_width, new_height), Image.Resampling.LANCZOS)
    
    # Apply flip if negative scale
    if matrix_scale_x < 0:
        image = image.transpose(Image.FLIP_LEFT_RIGHT)
    if matrix_scale_y < 0:
        image = image.transpose(Image.FLIP_TOP_BOTTOM)
    
    return image

def export_animation_frames(
    swf_path: Path,
    animation: AnimationInfo,
    output_folder: Path,
    total_anims: int,
    current_index: int
) -> bool:
    """Export animation frames as PNG sequence with matrix transformation applied"""
    
    # Create output folder
    anim_folder = output_folder / animation.name
    
    # Check overwrite mode
    if anim_folder.exists():
        if CONFIG["overwrite_mode"] == "skip":
            print(f"  ⊘ Skipping {animation.name} (already exists)")
            return True
        elif CONFIG["overwrite_mode"] == "prompt":
            response = input(f"  Overwrite {animation.name}? (y/n): ")
            if response.lower() != "y":
                print(f"  ⊘ Skipped {animation.name}")
                return True
        # overwrite mode: continue and replace
        shutil.rmtree(anim_folder)
    
    anim_folder.mkdir(parents=True, exist_ok=True)
    
    # Export frames using -selectid to export only child sprite at config scale
    print(f"  Extracting {animation.name}... ({current_index}/{total_anims})")
    
    args = [
        "-selectid", str(animation.child_id),
        "-zoom", str(CONFIG["scale_percent"]),
        "-export", "sprite",
        str(anim_folder),
        str(swf_path)
    ]
    
    if not run_ffdec_command(args):
        return False
    
    # Find the exported DefineSprite folder
    sprite_folders = list(anim_folder.glob("DefineSprite_*"))
    
    if not sprite_folders:
        print(f"  ⚠ No frames exported for {animation.name}")
        return False
    
    # Should only be one folder since we used -selectid
    sprite_folder = sprite_folders[0]
    frame_files = sorted(sprite_folder.glob("*.png"))
    
    if not frame_files:
        print(f"  ⚠ No PNG files found in {sprite_folder.name}")
        return False
    
    # Apply matrix transformation to each frame
    print(f"    Applying matrix transformation...")
    from PIL import Image
    
    for i, frame_file in enumerate(frame_files, start=1):
        with Image.open(frame_file) as img:
            # Apply matrix scale transformation
            transformed_img = apply_matrix_transform(
                img,
                animation.matrix_scale_x,
                animation.matrix_scale_y
            )
            transformed_img.save(frame_file)
        print(f"    Transformed {i}/{len(frame_files)}", end="\r")
    
    print(f"    ✓ {len(frame_files)} frames transformed")
    
    # Move frames up to animation folder
    for i, frame_file in enumerate(frame_files, start=1):
        new_path = anim_folder / frame_file.name
        shutil.move(str(frame_file), str(new_path))
        print(f"    Frame {i}/{len(frame_files)}", end="\r")
    
    print(f"    ✓ {len(frame_files)} frames extracted")
    
    # Remove the DefineSprite folder
    shutil.rmtree(sprite_folder)
    
    return True

# =========================
# MAIN EXTRACTION LOGIC
# =========================

def extract_swf_file(swf_path: Path):
    """Extract all animations from a single SWF file"""
    
    swf_id = swf_path.stem
    print(f"\n{'='*60}")
    print(f"Processing: {swf_path.name}")
    print(f"{'='*60}")
    
    # Create temp XML path
    temp_dir = get_temp_dir()
    xml_path = temp_dir / f"temp_{swf_id}.xml"
    
    try:
        # Step 1: Export XML
        if not export_swf_to_xml(swf_path, xml_path):
            raise Exception("Failed to export XML")
        
        # Step 2: Parse animations
        print(f"  Parsing animation structure...")
        animations = parse_swf_xml(xml_path)
        
        if not animations:
            print(f"  ⚠ No animations found in {swf_path.name}")
            return
        
        print(f"  Found {len(animations)} animations")
        
        # Step 3: Create output folder structure
        output_base = Path(CONFIG["output_folder"]) / swf_id
        frames_folder = output_base / "frames"
        frames_folder.mkdir(parents=True, exist_ok=True)
        
        # Step 4: Export bounds to JSON
        bounds_json_path = output_base / "bounds.json"
        export_bounds_to_json(animations, bounds_json_path)
        
        # Step 5: Export each animation (skip if JSON-only mode)
        if CONFIG["export_json_only"]:
            print(f"\n  {'='*56}")
            print(f"  JSON-only mode: Skipping frame extraction")
            print(f"  Bounds output: {bounds_json_path}")
            print(f"  {'='*56}")
            return
        
        success_count = 0
        for i, anim in enumerate(animations, start=1):
            try:
                if export_animation_frames(swf_path, anim, frames_folder, len(animations), i):
                    success_count += 1
            except Exception as e:
                error_msg = str(e)
                if CONFIG["error_mode"] == "fail_on_error":
                    raise
                else:
                    print(f"  ⚠ Error extracting {anim.name}: {error_msg}")
                    log_error(swf_path.name, anim.name, error_msg)
        
        # Summary
        print(f"\n  {'='*56}")
        print(f"  Extraction complete: {success_count}/{len(animations)} animations")
        print(f"  Frames output: {frames_folder}")
        print(f"  Bounds output: {bounds_json_path}")
        print(f"  {'='*56}")
        
    finally:
        # Cleanup temp XML
        if xml_path.exists() and not CONFIG["keep_temp_xml"]:
            xml_path.unlink()
            print(f"  Cleaned up temporary XML")

def extract_all_swf_files():
    """Extract all SWF files in input folder"""
    input_path = Path(CONFIG["input_folder"])
    
    if not input_path.exists():
        print(f"Error: Input folder not found: {input_path}")
        return
    
    # Get SWF files to process
    if CONFIG["process_single_file"]:
        swf_files = [input_path / CONFIG["process_single_file"]]
        if not swf_files[0].exists():
            print(f"Error: File not found: {swf_files[0]}")
            return
    else:
        swf_files = sorted(input_path.glob("*.swf"))
    
    if not swf_files:
        print(f"No SWF files found in {input_path}")
        return
    
    print(f"\n{'#'*60}")
    print(f"# Dofus Sprite Extractor with Matrix Transformation")
    if CONFIG["export_json_only"]:
        print(f"# MODE: JSON-only (bounds extraction)")
    else:
        print(f"# MODE: Full extraction (frames + bounds)")
    print(f"# Found {len(swf_files)} SWF file(s) to process")
    print(f"{'#'*60}")
    
    # Process each file
    for swf_file in swf_files:
        try:
            extract_swf_file(swf_file)
        except Exception as e:
            if CONFIG["error_mode"] == "fail_on_error":
                raise
            else:
                print(f"\n⚠ Failed to process {swf_file.name}: {e}")
                log_error(swf_file.name, "FILE_LEVEL", str(e))
    
    print(f"\n{'#'*60}")
    print(f"# All extractions complete!")
    print(f"{'#'*60}\n")

# =========================
# ENTRY POINT
# =========================

if __name__ == "__main__":
    extract_all_swf_files()