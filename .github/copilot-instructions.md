# Gofus Codebase Guide for AI Agents

## Project Overview
**Gofus** is a Godot 4.5 game project recreating game mechanics from Dofus, a 2D tactical MMO. The codebase uses GDScript with a **service-based architecture** featuring autoloaded singletons (managers) and a modular entity system.

---

## Architecture: Core Services

The game's logic is organized around **manager singletons** autoloaded in `project.godot`. Each manager is a single point of control for its domain:

### Manager Services (Autoloaded Singletons)
All singletons are accessed globally (e.g., `GameStateManager.current_mode`):

- **GameStateManager** (`scripts/core/game_state_manager.gd`): Central authority for game state
  - Tracks game modes (MAIN_MENU, EXPLORATION, FIGHT, DIALOGUE, TRANSITION)
  - Tracks game phases (LOADING, READY, PLAYING, PAUSED)
  - Maintains session data (player_id, character_id, play_time, current_map)
  - Emits `game_mode_changed` and `game_phase_changed` signals

- **EntityManager** (`scripts/core/entity_manager.gd`): Lifecycle and registry for all entities
  - Manages entity registration/unregistration and spawning/despawning
  - Stores entity metadata (type, position, map_id)
  - Emits signals when entities are registered/spawned

- **CommandManager** (`scripts/core/command_manager.gd`): Processes all player actions
  - Queue-based command processing (move, attack, use_item, interact)
  - Validates commands before execution
  - Maintains command history
  - **Pattern**: Commands are dictionaries with "type", "entity_id", and action-specific fields

- **EventBus** (`scripts/core/event_bus.gd`): Global event system for decoupled communication
  - Signals organized by domain: Fight, Movement, Interaction, Inventory, Character
  - **Example signals**: `attack_requested`, `item_acquired`, `level_up`, `movement_blocked`

- **FightManager** (`scripts/core/fight_manager.gd`): Manages all fight instances
  - Creates and starts fights, tracks active fights by ID

- **MapManager** (`scripts/core/map_manager.gd`): Handles map loading, cell queries, and terrain rendering
  - Provides texture lookups, pixel positioning, pathfinding

- **StaticDataManager** (`scripts/core/static_data_manager.gd`): Loads and caches static data
  - Loads spells, items, monster templates, maps, character classes from JSON
  - Pattern: Each data type has a `from_dict()` method for deserialization

---

## Data Model: Resources and Classes

**Data Classes** (in `assets/data/`) extend Resource and define data schemas:

- **PlayerData**: Runtime player state (name, level, exp, inventory, equipment, spells, stats)
- **EntityData**: Generic entity properties (id, hp, stats, position)
- **MonsterTemplate**: Static monster definitions (used to create instances)
- **SpellData**, **ItemData**, **ClassData**: Static game content

**Map Representation**:
- **Cell** (`scripts/maps/cell.gd`): Represents a single map cell
  - Gameplay properties: `walkable`, `ground_level`, `movement`, `object`
  - Rendering properties: `layer_ground_num`, `layer_object1_num`, `layer_object2_num` (with rotation/flip flags)
  - Deserialized from CSV map data parsed by MapParser

- **Map** (`scripts/maps/game_map.gd`): Scene node representing a complete map
  - Organizes cells into visual layers: Background, GroundLayer, Object1Layer, Object2Layer
  - Builds sprites from textures retrieved via MapManager
  - Lazy initialization: defers sprite creation until nodes are ready via `initialize()`

---

## Entity System: Controllers and Visuals

**Separation of Concerns**: Logic and rendering are decoupled.

- **EntityController** (`scripts/entities/entity_controller.gd`): Logic and state
  - Tracks position, movement, combat readiness
  - Registers with EntityManager in `_ready()`
  - Delegates to EntityVisuals for rendering

- **EntityVisuals** (`scripts/entities/entity_visuals.gd`): Animation and sprite management
  - References EntityController for state queries
  - Handles sprite selection, animation playback, frame updates

- **Subclasses**: PlayerController, MonsterController, NPCController extend EntityController with role-specific behavior

**Pattern**: All entities emit state change signals to EventBus (e.g., `movement_started`, `damage_taken`) so other systems can respond without direct coupling.

---

## Communication Patterns

### Signals-First Design
Systems communicate via EventBus signals rather than direct method calls. This enables decoupling:
```gdscript
# Example: Combat system listens to attack event
EventBus.attack_requested.connect(_on_attack_requested)

# Combat initiates attack
EventBus.emit_signal("attack_requested", attacker_id, target_id, spell_id)
```

### Command Queue Pattern
Player actions flow through CommandManager as commands:
1. UI or controller queues a command: `CommandManager.queue_command({"type": "move", "entity_id": "player_1", "target_position": Vector2(100, 200)})`
2. CommandManager validates command state (game must be PLAYING)
3. Executes command by emitting EventBus signal or calling method
4. Command history retained for replay/debugging

### Lazy Initialization
Nodes that depend on child nodes use deferred initialization:
- Map checks `is_node_ready()` in `initialize()` method
- If nodes not ready, stores data in `_pending_*` variables, builds in `_ready()`
- Prevents race conditions in complex scene hierarchies

---

## Asset Pipelines

### Sprite Extraction (`tools/sprites_extractor/sprite_extractor.py`)
- **Purpose**: Extracts character animations from Dofus SWF files into PNG sequences
- **Tool**: Requires FFDec (JPEXS Free Flash Decompiler) installed
- **Config** (in script): FFDec path, input/output folders, zoom level, error handling mode
- **Workflow**: SWF → XML (via FFDec) → Parse animation metadata → Extract frames as PNG → Apply flips if needed
- **Key insight**: Animations identified by sprite container IDs; flip status stored in matrix scaleX

### Map Parsing (`tools/map_parser/map_parser.gd`)
- Converts Dofus map CSV format into Cell objects
- Separates gameplay properties (walkable, ground_level) from rendering properties (layer_*_num, rotations, flips)
- Output used by Map to build visual layers

---

## Development Conventions

### Naming and Organization
- **Scripts**: Lowercase with underscores (`entity_controller.gd`)
- **Classes**: PascalCase (`class_name EntityController`)
- **Signals**: Snake_case, descriptive of what happened (`movement_completed`, `damage_dealt`)
- **Directories**: By domain (core/, entities/, maps/, systems/) not by file type

### Code Style
- **Region markers**: `#region Name` / `#endregion` used extensively for readability
- **Signals section**: Always list signals first in a script
- **Error handling**: Use `push_error()`, `push_warning()` for console feedback; managers print initialization/lifecycle events
- **Type hints**: Used in function signatures and key variables for clarity

### Debug Output
- Managers print initialization: `print("[ManagerName] Initialized")`
- Operations log what they do: `print("[Map] Map %d initialized with %d cells" % [map_id, cells.size()])`
- These logs help verify initialization order and catch state issues

---

## Common Tasks and Patterns

### Adding a New Command Type
1. Add to CommandManager validation/execution switch statements
2. Define command structure as comment or constant (e.g., `{"type": "cast_spell", "entity_id": "", "spell_id": "", "target_id": ""}`)
3. Emit appropriate EventBus signal in execute method
4. Listening system connects to signal and performs action

### Adding a New Entity Type
1. Create controller script extending EntityController (e.g., `npc_controller.gd`)
2. Override `_ready()` to set role-specific behavior
3. Create visuals script extending EntityVisuals
4. Emit EventBus signals for state changes
5. Register with EntityManager in controller's `_ready()`

### Adding a Game Mode
1. Add to GameStateManager.GameMode enum
2. Emit `game_mode_changed` signal when transitioning
3. Connected systems listen and enable/disable mode-specific logic
4. Update CommandManager validation to allow commands appropriate to the mode

---

## Key Files Reference

- `project.godot`: Autoload configuration, engine settings
- `scripts/core/`: All manager singletons (start here to understand flow)
- `scripts/entities/`: Entity controllers and visuals (understand entity lifecycle)
- `scripts/maps/`: Map and cell systems (understand rendering pipeline)
- `assets/data/`: Data class definitions (understand game data schemas)
- `scenes/Map.tscn`: Main map scene structure
- `tools/sprites_extractor/sprite_extractor.py`: SWF extraction workflow (reference for asset pipeline)
