# Dofus SWF Sprite Extractor - Documentation

## Overview

This Python script extracts character animations from Dofus SWF files and converts them into PNG sequences with proper sprite centering metadata. It uses FFDec (JPEXS Free Flash Decompiler) to parse SWF files, extract sprites, apply transformation matrices, and export bounds information for runtime offset application.

---

## Requirements

- **Python 3.7+** with `Pillow` library (`pip install Pillow`)
- **Java Runtime Environment** (to run FFDec JAR)
- **FFDec** (JPEXS Free Flash Decompiler) as JAR file
- **Input folder** containing SWF files to process
- **Output folder** where extracted animations will be saved

---

## Configuration

Edit the `CONFIG` dictionary at the top of the script:

```python
CONFIG = {
    "ffdec_path": r"C:\Users\Moi\Documents\jpexs-decompiler\dist\ffdec.jar",
    "input_folder": "extract_sprites_test_input",
    "output_folder": "extract_sprites_test_output",
    "scale_percent": 2.0,
    "error_mode": "skip_with_warning",
    "overwrite_mode": "skip",
    "keep_temp_xml": False,
    "debug_mode": True,
    "process_single_file": "",
}
```

### Configuration Options

| Option | Type | Description |
|--------|------|-------------|
| `ffdec_path` | str | Path to FFDec JAR file |
| `input_folder` | str | Folder containing source SWF files |
| `output_folder` | str | Destination for extracted animations |
| `scale_percent` | float | Export zoom level (2.0 = 200%) for high-quality output |
| `error_mode` | str | `"skip_with_warning"` or `"fail_on_error"` |
| `overwrite_mode` | str | `"skip"`, `"overwrite"`, or `"prompt"` |
| `keep_temp_xml` | bool | Keep temporary XML files for debugging |
| `debug_mode` | bool | Show detailed extraction progress |
| `process_single_file` | str | Filename to process (empty = process all) |

---

## How It Works

### 1. **XML Export**
   - Converts SWF binary structure to readable XML using FFDec
   - Temporary XML stored in system temp directory

### 2. **Animation Discovery**
   - Parses XML to find exported symbol names (e.g., "walkF", "runL")
   - Maps symbol names to parent container sprite IDs
   - Identifies child sprites referenced by containers
   - Extracts transformation matrix from PlaceObject2Tag
   - Reads bounds from parent container sprite

### 3. **Frame Extraction with Transformation**
   - Exports child sprite at configured scale (high quality)
   - Applies parent's transformation matrix to each frame:
     - Horizontal flip if `scaleX < 0`
     - Vertical flip if `scaleY < 0`
     - Resize if `scaleX` or `scaleY` ≠ 1.0
   - Matrix values are rounded to 2 decimal places (e.g., 1.0012054 → 1.00)

### 4. **Bounds Export**
   - Extracts bounds from parent container sprite
   - Scales bounds by `config_scale` only (not by matrix scale)
   - Exports to `bounds.json` in character root folder
   - Bounds enable proper sprite centering at runtime

### 5. **Cleanup**
   - Removes intermediate DefineSprite folders
   - Optionally removes temporary XML files
   - Logs any errors to `extraction_errors.log`

---

## Output Structure

```
output_folder/
└── [character_id]/
    ├── bounds.json          ← Sprite offset metadata
    └── frames/
        ├── walkF/
        │   ├── 1.png
        │   ├── 2.png
        │   └── 3.png
        ├── walkL/
        │   ├── 1.png        (horizontally flipped if scaleX < 0)
        │   └── 2.png
        └── runF/
            ├── 1.png
            └── 2.png
```

### bounds.json Format

```json
{
  "walkF": {
    "horizontal": -46.70,
    "vertical": -138.00
  },
  "runL": {
    "horizontal": -64.70,
    "vertical": -149.30
  }
}
```

**Calculation:** `final_bound = parent_bound * config_scale`

Example: `-23.35 * 2.0 = -46.70`

---

## Usage

### Process All SWF Files
```bash
python extract_swf_sprites.py
```

### Process Single File
Set `CONFIG["process_single_file"] = "filename.swf"` and run:
```bash
python extract_swf_sprites.py
```

---

## Understanding the Extraction Process

### XML Structure Example

```xml
<!-- Parent Container -->
<item type="DefineSpriteTag" spriteId="120">
  <subTags>
    <!-- Child Reference with Transformation -->
    <item type="PlaceObject2Tag" characterId="119">
      <matrix scaleX="-1.00" scaleY="1.00" translateX="0" translateY="0"/>
    </item>
  </subTags>
  <bounds horizontal="-32.350" vertical="-74.650"/>
</item>

<!-- Export Mapping -->
<item type="ExportAssetsTag">
  <tags><item>120</item></tags>
  <names><item>runL</item></names>
</item>
```

### Extraction Steps for "runL"

1. **Find Export:** "runL" → container sprite ID 120
2. **Find Child:** Container 120 → child sprite ID 119
3. **Read Matrix:** scaleX = -1.00 (flip horizontal), scaleY = 1.00
4. **Export Child:** Export sprite 119 at scale 2.0
5. **Transform Frames:** Apply matrix (flip horizontally, no resize needed)
6. **Export Bounds:** Parent bounds (-32.35, -74.65) × 2.0 = (-64.70, -149.30)

---

## Error Handling

### Error Modes

- **`skip_with_warning`**: Logs errors and continues processing
- **`fail_on_error`**: Stops execution on first error

### Error Log

Failures are logged to `extraction_errors.log` with format:
```
[timestamp] | [swf_file] | [animation_name] | [error_message]
```

---

## Key Functions

### `parse_swf_xml(xml_path) -> List[AnimationInfo]`
Extracts animation metadata from SWF XML structure.

**Returns:** List of animations with:
- Name, container ID, child sprite ID
- Matrix transformation (scaleX, scaleY)
- Parent bounds (horizontal, vertical)

### `apply_matrix_transform(image, matrix_scale_x, matrix_scale_y)`
Applies transformation matrix to exported PNG frames.

**Transformations:**
- Resize if scale ≠ 1.0
- Flip horizontally if scaleX < 0
- Flip vertically if scaleY < 0

### `export_bounds_to_json(animations, output_path)`
Exports bounds metadata scaled by config value.

**Formula:** `final_bound = parent_bound * config_scale`

### `export_animation_frames(swf_path, animation, output_folder, ...)`
Main frame extraction pipeline.

**Steps:** FFDec export → load PNGs → apply matrix → save transformed frames

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| "FFDec command timed out" | Increase timeout in `run_ffdec_command()` |
| "No frames exported" | Check if SWF contains valid sprite definitions |
| Bounds are 0.0 | Enable `keep_temp_xml` and verify bounds exist in XML |
| Flipped animations look wrong | Verify matrix scaleX/scaleY values in temp XML |
| Java error | Ensure Java is installed and accessible via PATH |

---

## Matrix Transformation Details

### Why Apply Matrix?

In Dofus SWF files, animations like "walkL" (walk left) reuse "walkR" (walk right) sprites with a negative scaleX to flip them horizontally. The parent container defines this transformation, but the child sprite is stored unflipped.

**Without matrix application:**
- Child sprite exports facing right
- Bounds from child don't account for flip
- Runtime offset is incorrect

**With matrix application:**
- Child sprite is transformed during export
- Exported frames already face correct direction
- Bounds from parent match transformed sprite
- Runtime offset is correct

### Matrix Components Used

- **scaleX**: Horizontal scale (negative = flip)
- **scaleY**: Vertical scale (negative = flip)
- **Rounded to 2 decimals** for cleaner metadata

**Not currently used:**
- Rotation (rotateSkew0, rotateSkew1)
- Translation (translateX, translateY)

---

## Integration with Godot

Extracted frames and bounds are ready for:
- AnimatedSprite2D with custom offset component
- SpriteFrames resources with metadata
- Runtime offset application via bounds.json

Recommended workflow:
1. Extract frames with this script
2. Import into Godot project
3. Use GDScript importer to create SpriteFrames resources
4. Apply bounds as sprite offsets at runtime

See **Godot SpriteFrames Importer Documentation** for next steps.

---

## Notes

- **Scale Quality**: Higher `scale_percent` = better quality but larger files
- **Matrix Rounding**: Values rounded to 2 decimals for consistency
- **Bounds Source**: Always from parent container, never from child
- **Temp Files**: Stored in system temp, cleaned automatically
- **Thread Safety**: Not thread-safe; process files sequentially
- **JAR Execution**: Requires Java in PATH or full java.exe path