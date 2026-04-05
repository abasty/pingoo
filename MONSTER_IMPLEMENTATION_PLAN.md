# Monster System Implementation Plan

## Overview

This document outlines the technical plan for implementing the Monster and Egg system into the Pingoo game. The implementation is structured in layers, starting with core data structures, then scene/script pairs, and finally integration into the existing game loop.

---

## Phase 1: Data and Initialization

### 1.1 Extend `game_state.gd`

Add tracking for egg-related and monster crush game state that persists across level retries but resets on new level:

```gdscript
# Per-level state (reset on level start)
var egg_containers: Array[Vector2] = []  # Positions of 3 blocks containing eggs
var eggs_destroyed: int = 0               # Count of eggs destroyed (0-3)
var eggs_spawned: int = 0                 # Count of eggs that have hatched (0-3)
var next_egg_spawn_time: float = 20.0    # Seconds elapsed until next egg hatches
var last_hatch_time: float = 0.0         # Level time when last egg hatched
var monsters_crushed: int = 0             # Count of monsters crushed by blocks (0-3)

func reset_egg_state():
	egg_containers.clear()
	eggs_destroyed = 0
	eggs_spawned = 0
	next_egg_spawn_time = 20.0
	last_hatch_time = 0.0
	monsters_crushed = 0
```

### 1.2 Extend `test.gd` initialization

During board generation (`_ready()`), after ice blocks are placed:

```gdscript
func _select_egg_containers() -> void:
	"""Randomly select 3 ice blocks to contain eggs."""
	if blocks.size() < 3:
		return  # Safety check

	blocks.shuffle()
	game_state.egg_containers = []

	for i in range(3):
		var block = blocks[i]
		game_state.egg_containers.append(block.position)
```

Call `_select_egg_containers()` at the end of board generation, right after gifts and trees are placed.

---

## Phase 2: Egg Visibility System

### 2.1 Create `egg_indicator.tscn` and `egg_indicator.gd`

A temporary visual overlay that marks egg-containing blocks for the first 3 seconds.

```gdscript
# egg_indicator.gd
extends Node2D

class_name EggIndicator

@export var duration: float = 3.0
@onready var color_rect = $ColorRect  # A rounded-corner rect shape
var elapsed: float = 0.0

func _ready():
	modulate.a = 0.8  # Semi-transparent

func _process(delta):
	elapsed += delta
	if elapsed >= duration:
		queue_free()

	# Optional: fade out in last 0.5 seconds
	if elapsed > duration - 0.5:
		modulate.a = 0.8 * ((duration - elapsed) / 0.5)
```

**Scene structure** (`egg_indicator.tscn`):
```
EggIndicator (Node2D)
├─ ColorRect (40x40, red border, rounded corners ~5px)
└─ CollisionShape2D (optional, for debugging)
```

### 2.2 Update `test.gd` to spawn egg indicators

Add to `_ready()` after egg containers are selected:

```gdscript
func _spawn_egg_indicators() -> void:
	"""Spawn visual egg indicator overlays for 3 seconds."""
	for pos in game_state.egg_containers:
		var indicator = load("res://egg_indicator.tscn").instantiate()
		add_child(indicator)
		indicator.position = pos
		indicator.position += Vector2(20, 20)  # Center on tile
```

---

## Phase 3: Monster Scene and Script

### 3.1 Create `monster.tscn` and `monster.gd`

Monsters are semi-autonomous entities that move toward the player while incorporating random navigation.

```gdscript
# monster.gd
extends Node2D

class_name Monster

const TILE_SIZE: int = 40
const MOVE_SPEED: float = 100.0  # pixels/sec
const DECISION_INTERVAL: float = 1.0  # Re-evaluate target every 1 second

var target: Vector2  # Next tile target
var decision_timer: float = 0.0
var santa_ref: Node2D  # Reference to Santa for proximity-seeking

func _ready():
	santa_ref = get_tree().root.get_node("test/Santa")
	_choose_next_target()

func _process(delta):
	# Update decision timer
	decision_timer += delta
	if decision_timer >= DECISION_INTERVAL:
		decision_timer = 0.0
		_choose_next_target()

	# Move toward target
	var direction = (target - position).normalized()
	position += direction * MOVE_SPEED * delta

	# Snap to target when close enough
	if position.distance_to(target) < MOVE_SPEED * delta:
		position = target
		_choose_next_target()

func _choose_next_target() -> void:
	"""Pick the next tile to move toward, biasing toward Santa."""
	var current_tile = position / TILE_SIZE
	var candidates: Array[Vector2] = []

	# Get 4 adjacent tiles
	var directions = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
	for dir in directions:
		var candidate_tile = current_tile + dir
		var candidate_world = candidate_tile * TILE_SIZE + Vector2(20, 20)

		# Check if tile is valid and empty (no ice block, no tree, no Santa)
		if _is_tile_free(candidate_tile):
			candidates.append(candidate_world)

	if candidates.is_empty():
		return  # Stuck, stay in place

	# Sort by distance to Santa (closest first)
	candidates.sort_custom(func(a, b):
		var dist_a = a.distance_to(santa_ref.position)
		var dist_b = b.distance_to(santa_ref.position)
		return dist_a < dist_b
	)

	# 70% chance to move closer to Santa, 30% random alternative
	if randf() < 0.7 and not candidates.is_empty():
		target = candidates[0]
	else:
		target = candidates[randi() % candidates.size()]

func _is_tile_free(tile_pos: Vector2) -> bool:
	"""Check if a tile contains no blocking entities."""
	# Guard against out-of-bounds
	if tile_pos.x < 0 or tile_pos.x >= 20 or tile_pos.y < 0 or tile_pos.y >= 20:
		return false

	var world_pos = tile_pos * TILE_SIZE + Vector2(20, 20)

	# Check for trees
	var trees = get_tree().get_nodes_in_group("trees")
	for tree in trees:
		if tree.position.distance_to(world_pos) < 5:
			return false

	# Check for ice blocks
	var blocks = get_tree().get_nodes_in_group("ice_blocks")
	for block in blocks:
		if block.position.distance_to(world_pos) < 5:
			return false

	# Check for gifts
	var gifts = get_tree().get_nodes_in_group("gifts")
	for gift in gifts:
		if gift.position.distance_to(world_pos) < 5:
			return false

	return true

func get_tile_position() -> Vector2:
	"""Return the grid tile coordinates."""
	return position / TILE_SIZE
```

**Scene structure** (`monster.tscn`):
```
Monster (Node2D)
├─ ColorRect (40x40, red fill, no border)
└─ Area2D (collision shape: rect 40x40)
```

### 3.2 Add monster to groups

Update `monster.gd` `_ready()`:

```gdscript
func _ready():
	add_to_group("monsters")
	santa_ref = get_tree().root.get_node("test/Santa")
	_choose_next_target()
```

---

## Phase 4: Egg Hatching and Spawning Logic

### 4.1 Update `test.gd` main loop

Add egg-spawning logic to `_process(delta)`:

```gdscript
func _process(delta):
	# Existing logic...

	# Update egg spawning
	_update_egg_spawning(delta)

func _update_egg_spawning(delta) -> void:
	"""Check if the next egg should hatch and spawn a monster if so."""
	if not game_state.is_level_running:
		return

	# Check if next egg should spawn
	if (game_state.level_time_left < game_state.next_egg_spawn_time and
		game_state.eggs_spawned < 3 - game_state.eggs_destroyed):

		# Spawn monster at the next egg container position
		_spawn_monster_at_egg()

		# Update counters
		game_state.last_hatch_time = game_state.level_time_left
		game_state.eggs_spawned += 1

		# Schedule next egg
		if game_state.eggs_spawned < 3:
			game_state.next_egg_spawn_time -= 15.0

func _spawn_monster_at_egg() -> void:
	"""Instantiate a monster at the next available egg position."""
	if game_state.eggs_spawned >= game_state.egg_containers.size():
		return

	var egg_pos = game_state.egg_containers[game_state.eggs_spawned]
	var monster = load("res://monster.tscn").instantiate()
	add_child(monster)
	monster.position = egg_pos + Vector2(20, 20)  # Center on tile
```

---

## Phase 5: Egg Destruction Bonus

### 5.1 Update `ice_block.gd`

Add egg-block detection and trigger special effect:

```gdscript
# In ice_block.gd
var contains_egg: bool = false

func _ready():
	# ... existing code ...

	# Check if this block contains an egg at level start
	contains_egg = position in game_state.egg_containers

func _on_destroyed():
	"""Called when this block breaks."""
	if contains_egg:
		_handle_egg_destruction()

	# ... existing destruction code ...

func _handle_egg_destruction() -> void:
	"""Award bonus when an egg-containing block is destroyed."""
	game_state.eggs_destroyed += 1

	# Play special animation (optional: shake, flash, particle effect)
	# For now, just award bonus
	var bonus: int
	match game_state.eggs_destroyed:
		1: bonus = 200
		2: bonus = 300
		3: bonus = 500
		_: bonus = 0

	if bonus > 0:
		$Score.add(bonus)  # Assuming Score is accessible, or use get_node
```

Ensure `ice_block.gd` is added to a group at `_ready()`:

```gdscript
func _ready():
	add_to_group("ice_blocks")
	# ... rest of _ready()
```

Similarly, ensure `tree.gd` and `gift.gd` are in their respective groups:

```gdscript
# tree.gd _ready()
add_to_group("trees")

# gift.gd _ready()
add_to_group("gifts")
```

### 5.2 Monster-block crush mechanics

When an ice block is pushed and slides across tiles, it may encounter monsters in its path.
Update `ice_block.gd::push()` to detect, crush, and award bonus points to monsters:

```gdscript
# In ice_block.gd
func push(v: Vector2) -> void:
	# ... existing push setup code ...

func _process(delta):
	# ... existing movement code ...

	# During slide, check for monster collisions
	if state == State.MOVING:
		_check_monster_crush()

func _check_monster_crush() -> void:
	"""Check if this moving block is occupying any monsters' tiles and crush them all."""
	var block_tile = position / TILE_SIZE
	var monsters = get_tree().get_nodes_in_group("monsters")
	var crushed_in_this_frame: Array[Monster] = []

	# Find all monsters on the block's tile
	for monster in monsters:
		var monster_tile = monster.get_tile_position()
		if block_tile.distance_to(monster_tile) < 0.5:
			crushed_in_this_frame.append(monster)

	# Calculate crush multiplier based on count in this frame
	var crush_multiplier: int = crushed_in_this_frame.size()

	# Crush all found monsters and award bonuses (multiplied by crush count)
	for monster in crushed_in_this_frame:
		monster.queue_free()
		_crush_monster_award_bonus(crush_multiplier)

func _crush_monster_award_bonus(multiplier: int = 1) -> void:
	"""Award score bonus for crushing a monster, multiplied by crush count in this push."""
	game_state.monsters_crushed += 1

	var bonus: int = 0
	match game_state.monsters_crushed:
		1: bonus = 200
		2: bonus = 300
		3: bonus = 500
		_: bonus = 0

	# Apply multiplier based on number of monsters crushed in this push
	bonus *= multiplier

	if bonus > 0:
		get_tree().root.get_node("test/Score").add(bonus)
```

---

## Phase 6: Monster-Player Collision Detection

### 6.1 Update `test.gd` collision checking

Add per-frame collision detection between all monsters and Santa:

```gdscript
func _process(delta):
	# Existing logic...
	_check_monster_collisions()

func _check_monster_collisions() -> void:
	"""Check if any monster occupies Santa's tile."""
	if not game_state.is_level_running:
		return

	var santa_tile = $Santa.position / TILE_SIZE
	var monsters = get_tree().get_nodes_in_group("monsters")

	for monster in monsters:
		var monster_tile = monster.get_tile_position()
		if santa_tile.distance_to(monster_tile) < 0.5:
			# Collision!
			_on_monster_collision(monster)
			break

func _on_monster_collision(monster: Monster) -> void:
	"""Handle monster collision with Santa."""
	# Remove the monster
	monster.queue_free()

	# Lose a life
	game_state.lose_life()

	# Pause and show dialog
	game_state.is_level_running = false

	# If game is over, show game-over dialog
	if game_state.is_game_over():
		end_menu.show_game_over()
	else:
		# Show fail dialog (similar to timeout)
		end_menu.show_fail(game_state.lives)
```

---

## Phase 7: Integration with Existing Fail/Retry Logic

### 7.1 Update `end_menu.gd` to distinguish failure types

The `end_menu.gd` must distinguish between timeout-based failures (restart the level)
and monster collision failures (resume without restart):

Add an enum to track failure source:

```gdscript
# In end_menu.gd
enum FailureType { TIMEOUT, MONSTER_COLLISION }
var current_failure_type: FailureType = FailureType.TIMEOUT
```

Update the `show_fail()` method to accept failure type:

```gdscript
func show_fail(lives_left: int, failure_type: FailureType = FailureType.TIMEOUT) -> void:
	current_failure_type = failure_type
	# ... existing dialog setup ...
	$FailDialog.dialog_text = "Temps ecoule! Vies restantes: %d" % lives_left
	if failure_type == FailureType.MONSTER_COLLISION:
		$FailDialog.dialog_text = "Monstre! Vies restantes: %d" % lives_left
	$FailDialog.popup_centered_ratio(0.5)
	mode = OverlayMode.FAIL
```

Update the primary button handler to branch based on failure type:

```gdscript
func _on_primary_button_pressed() -> void:
	match mode:
		OverlayMode.FAIL:
			if current_failure_type == FailureType.TIMEOUT:
				# Timeout: restart the level
				game_state.start_level()
			else:
				# Monster collision: resume from current state
				_resume_level()
		OverlayMode.GAME_OVER:
			# ... existing game over logic ...
```

Add a new `_resume_level()` helper:

```gdscript
func _resume_level() -> void:
	"""Resume level gameplay without restarting or resetting the board."""
	game_state.is_level_running = true
	# Monster was already removed during collision detection
	# Board state is preserved; just unpause
	mode = OverlayMode.NONE
	hide()
```

### 7.2 Update `test.gd` to call the new `show_fail()` signature

When handling monster collision, pass the failure type:

```gdscript
func _on_monster_collision(monster: Monster) -> void:
	"""Handle monster collision with Santa."""
	# Remove the monster
	monster.queue_free()

	# Lose a life
	game_state.lose_life()

	# Pause and show dialog
	game_state.is_level_running = false

	# If game is over, show game-over dialog
	if game_state.is_game_over():
		end_menu.show_game_over()
	else:
		# Show fail dialog with monster-collision type
		end_menu.show_fail(game_state.lives, end_menu.FailureType.MONSTER_COLLISION)
```

When handling timeout (existing code), it will use the default `TIMEOUT` type:

```gdscript
func _on_level_timeout() -> void:
	# ... existing timeout handling ...
	if game_state.is_game_over():
		end_menu.show_game_over()
	else:
		# Default failure type is TIMEOUT, so no need to pass it explicitly
		end_menu.show_fail(game_state.lives)
```

---

## Phase 8: Scene and Array Management

### 8.1 Update `test.gd` level cleanup

When a level restarts or ends, clear all monsters:

```gdscript
func _cleanup_level() -> void:
	"""Clear all dynamic objects before loading a new level."""
	var monsters = get_tree().get_nodes_in_group("monsters")
	for monster in monsters:
		monster.queue_free()

	# ... existing cleanup code ...
```

Call `_cleanup_level()` before `start_level()` or at the end of level success/failure.

---

## Implementation Checklist

- [ ] **Phase 1**: Extend `game_state.gd` with egg state tracking
- [ ] **Phase 1**: Call `_select_egg_containers()` in board generation
- [ ] **Phase 2**: Create `egg_indicator.tscn` and `egg_indicator.gd`
- [ ] **Phase 2**: Call `_spawn_egg_indicators()` in `test.gd::_ready()`
- [ ] **Phase 3**: Create `monster.tscn` with colored rect
- [ ] **Phase 3**: Create `monster.gd` with navigation and target-seeking logic
- [ ] **Phase 3**: Add monsters to "monsters" group
- [ ] **Phase 4**: Add `_update_egg_spawning()` to `test.gd::_process()`
- [ ] **Phase 4**: Add `_spawn_monster_at_egg()` to `test.gd`
- [ ] **Phase 5**: Update `ice_block.gd` to detect and reward egg destruction
- [ ] **Phase 5**: Add ice blocks, trees, gifts to their respective groups
- [ ] **Phase 5.2**: Extend `game_state.gd` with `monsters_crushed` counter
- [ ] **Phase 5.2**: Add monster-crush detection to `ice_block.gd::push()` and `_process()`
- [ ] **Phase 5.2**: Add `_check_monster_crush()` method to ice_block.gd
- [ ] **Phase 5.2**: Add `_crush_monster_award_bonus()` method to ice_block.gd
- [ ] **Phase 6**: Add `_check_monster_collisions()` to `test.gd::_process()`
- [ ] **Phase 6**: Add `_on_monster_collision()` handler to `test.gd`
- [ ] **Phase 7.1**: Add `FailureType` enum to `end_menu.gd`
- [ ] **Phase 7.1**: Update `show_fail()` to accept failure type parameter
- [ ] **Phase 7.1**: Update button handler in `end_menu.gd` to branch on failure type
- [ ] **Phase 7.1**: Add `_resume_level()` method to `end_menu.gd`
- [ ] **Phase 7.2**: Update `_on_monster_collision()` to pass `MONSTER_COLLISION` type
- [ ] **Phase 7.2**: Verify timeout handler uses default `TIMEOUT` type
- [ ] **Phase 8**: Add `_cleanup_level()` and call it on level transitions
- [ ] **Testing**: Verify egg indicators appear and disappear at level start
- [ ] **Testing**: Verify eggs spawn at correct times (20s, 35s, 50s)
- [ ] **Testing**: Verify monster collision loses a life
- [ ] **Testing**: Verify egg destruction grants correct bonuses (200/300/500)
- [ ] **Testing**: Verify monsters navigate toward Santa
- [ ] **Testing**: Verify block crush mechanics: pushed block carrying monster across tiles
- [ ] **Testing**: Verify crushed monster is removed and correct bonus is awarded (200/300/500)
- [ ] **Testing**: Verify crush bonus counter increments correctly
- [ ] **Testing**: Verify bonus is multiplied when multiple monsters are crushed in one push
  (e.g., 2 monsters crushed: 1st gets 200×2=400, 2nd gets 300×2=600)
- [ ] **Testing**: Verify monster collision "continue" resumes level (no board restart)
- [ ] **Testing**: Verify monster collision "continue" preserves timer and board state
- [ ] **Testing**: Verify timeout "continue" still restarts the level (different from monster collision)
- [ ] **Testing**: Verify retry/abandon flows work after monster collision
- [ ] **Future**: Replace red rect with sprite sheet and animation

---

## Notes on Future Sprite Enhancement

When moving from red squares to animated sprites:

1. Add a `@export var monster_sprite: Texture2D` to `monster.gd`.
2. Replace `ColorRect` in `monster.tscn` with `AnimatedSprite2D`.
3. Update `_ready()` to initialize the animation.
4. Consider adding idle, walk, and death animation states.

This keeps the current placeholder-based logic intact while allowing easy sprite swapping later.

---

## Game Flow: New Mechanics

### Monster-Block Crush Mechanics

When a player pushes an ice block, it slides in a straight line until it hits an obstacle or
reaches an empty space. If a monster is in the block's path:

1. The block passes through the monster's tile during slide.
2. The collision detector in `_check_monster_crush()` identifies the overlap.
3. The monster is marked as crushed and queued for deletion.
4. The block continues its slide normally and stops at its final destination.
5. Only the first monster in the path is crushed; remaining monsters in other tiles continue
   moving independently.

**Gameplay Implication**: This adds a risk/reward mechanic—players can use blocks as defensive
tools to remove threats, but it requires precise timing and positioning.

### Monster Collision: Resume vs. Restart

Two types of failure trigger the `FAIL` overlay:

- **Timeout** (timer reaches 0): Clicking "continue" restarts the entire level.
  - Board regenerates
  - Timer resets to 60s
  - Monsters respawn according to their schedule
  - This is punishing but gives a clean slate.

- **Monster Collision** (Santa touches a monster): Clicking "continue" resumes the level.
  - Board state is preserved exactly as it was
  - Timer continues counting down from where it was paused
  - The colliding monster is removed; other monsters continue their movement
  - This is more forgiving, allowing players to recover from a single mistake

**Implementation Detail**: `end_menu.gd` distinguishes failure types via the `FailureType` enum
and routes the primary button to either `game_state.start_level()` (restart) or
`_resume_level()` (unpause).

---

## Risk Mitigation

- **Pathfinding deadlock**: If all adjacent tiles are blocked, the monster stays in place. This is acceptable for early prototyping.
- **Performance overhead**: With only 1-3 monsters on screen, updating navigation every 1 second is negligible.
- **Collision edge cases**: Using tile-to-tile distance (< 0.5 threshold) ensures one-pixel overlap is caught reliably.
- **Spawning before deletion**: Added `queue_free()` to ensure monsters are removed cleanly on retry/new level.
