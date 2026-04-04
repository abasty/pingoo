# Pingoo Architecture

## Overview

Pingoo is a small Godot 4.6 game built around a single main scene and a
grid-based puzzle loop. The player controls Santa, moves on a fixed 40x40 tile
grid, pushes movable objects, breaks ice blocks for points, and solves the level
by aligning the three gift boxes.

The architecture is intentionally simple:

- `test.tscn` is the main scene and acts as the runtime composition root.
- `test.gd` procedurally generates the playable board at startup.
- Each gameplay object owns its own movement and animation logic.
- Lightweight signals are used for cross-node communication such as score
  updates and gift alignment checks.

## High-Level Structure

### Main entry point

- `project.godot` sets `res://test.tscn` as the main scene.
- `test.tscn` assembles the static root-level nodes:
  - `Background`
  - `Santa`
  - `Score`
  - `JingleBells`
  - `Music`

### Scene responsibilities

- `test.tscn` / `test.gd`
  - Own the board generation.
  - Track spawned trees, ice blocks, and gifts.
  - Evaluate the puzzle success condition after gifts move.
  - Trigger end-state celebration effects and bonus scoring.

- `santa.tscn` / `santa.gd`
  - Represent the player character.
  - Read input.
  - Enforce tile-by-tile movement.
  - Attempt push interactions against adjacent colliders.

- `ice_block.tscn` / `ice_block.gd`
  - Represent movable and destructible blocks.
  - Slide by one tile when pushed into free space.
  - Break immediately if pushed into an occupied tile.
  - Emit score increments when destroyed.

- `gift.tscn` / `gift.gd`
  - Represent movable puzzle targets.
  - Behave like pushable blocks, but do not break.
  - Emit a notification when movement finishes so the board can re-check the win
    condition.

- `tree.tscn` / `tree.gd`
  - Represent static obstacles and decorative border elements.
  - Become animated during the success sequence by moving around the board
    perimeter.

- `score.tscn` / `score.gd`
  - Display the score using a six-digit sprite-based counter.
  - Animate the displayed digits until they reach the target score.

- `background.tscn`
  - Provide the static board background.

## Runtime Model

### Board and coordinate system

The game uses an 800x800 viewport and a 20x20 logical grid.

- Tile size: `40x40` pixels.
- Valid tile coordinates: `0..19` on both axes.
- Most dynamic objects snap to exact tile coordinates before accepting another
  movement input.

The board origin is the top-left corner. Objects are positioned directly in
pixel space as:

`Vector2(column * 40, row * 40)`

This means the project does not maintain a separate board-state matrix. Instead,
world positions are the source of truth.

### Main loop ownership

There is no central gameplay state machine. Instead, behavior is distributed:

- `Santa` reacts to player input every frame.
- `Gift`, `IceBlock`, and `Tree` advance their own movement when their local
  state allows it.
- `Score` advances its own display animation toward `target_value`.
- `test.gd` performs setup and listens for important events.

This keeps object logic local, at the cost of some implicit coupling through
positions and scene-tree lookups.

## Scene Graph

At runtime, the main tree looks roughly like this:

```text
test (Node2D)
|- Background (instance of background.tscn)
|- Santa (instance of santa.tscn)
|- Score (instance of score.tscn)
|- JingleBells (AudioStreamPlayer)
|- Music (AudioStreamPlayer)
|- Tree* (spawned dynamically)
|- IceBlock* (spawned dynamically)
`- Gift* (spawned dynamically)
```

The dynamic children are instantiated by `test.gd` during `_ready()`.

## Startup and Level Generation

`test.gd` is the procedural level builder.

### Generation sequence

When the main scene enters the tree:

1. Border trees are spawned around the full outer ring of the grid.
2. Ice blocks are generated through the inner play area using a regular pattern.
3. Additional adjacent blocks are randomly added to vary the layout.
4. Three existing inner blocks are replaced with gifts.
5. Five existing inner blocks are replaced with trees.
6. The score display is raised above other nodes using `z_index`.

### Data tracked by `test.gd`

`test.gd` maintains three arrays:

- `blocks`: inner ice blocks eligible for replacement during setup.
- `gifts`: references to the three spawned gifts.
- `trees`: references to all spawned trees, including border trees and
  replacement trees.

These arrays are not a full spatial model. They are mainly used for setup-time
selection and later celebration/win behavior.

## Movement Architecture

### Common pattern

Santa, gifts, blocks, and trees all use the same broad movement strategy:

- Each object stores a `target` position.
- Movement begins only when current `position == target`.
- A new target is chosen exactly one tile away.
- Each frame interpolates toward that target at a fixed speed.
- Movement ends by snapping to the exact target when close enough.

This gives clean grid movement while still rendering smoothly.

### Collision probing

Santa, gifts, and ice blocks rely on `PhysicsRayQueryParameters2D` and
`intersect_ray()` to look one tile ahead.

Implications:

- Collision is checked just before committing to movement.
- The project does not use a dedicated tilemap or pathfinding system.
- Push interactions are implemented by discovering the blocking node and calling
  a method on it.

### Player movement

`santa.gd` handles input and movement directly.

Rules:

- Only one axis is used per move.
- Horizontal input takes precedence over vertical input if both are pressed.
- A new move is only accepted when Santa is exactly on a tile.
- If the target tile is empty, Santa moves there.
- If the tile is occupied and the collider exposes `push`, pressing Space
  triggers the push attempt.

Santa therefore acts as the initiator for all object interactions.

### Pushable objects

`gift.gd` and `ice_block.gd` both expose `push(v: Vector2)`.

Shared behavior:

- Ignore push requests unless idle.
- Cache the push direction as velocity.
- Use a one-tile raycast to determine the result.

Different outcomes:

- Gift:
  - Moves one tile if the next tile is free.
  - Cancels the move if blocked.
  - Emits `gift_moved` when motion completes.

- Ice block:
  - Moves one tile if the next tile is free.
  - Enters `BREAKING` state if blocked immediately.
  - Plays movement or breaking audio accordingly.
  - Emits `add_score(10)` when it breaks.
  - Frees itself after the destroy animation finishes.

### Celebration tree movement

`tree.gd` is mostly inert until `bling()` is called.

After activation:

- Trees enter the `BLING` state.
- Each tree walks around the outer perimeter clockwise.
- The next target tile is chosen based on exact current edge position.

This effect is independent per tree and does not require central coordination
once started.

## Scoring Architecture

The score system is intentionally local and presentation-driven.

### Producer side

- Ice blocks award `10` points when destroyed.
- Gift alignment awards `1000` points.

### Consumer side

`score.gd` tracks:

- `target_value`: the authoritative score.
- `value`: the last fully settled displayed value.

When score changes:

- Producers call `Score.add(score)`.
- The display does not jump immediately.
- `_process()` calls `animate(delta)` until all digits visually roll into the
  new state.

Each digit is a sprite with a moving `region_rect`, so the counter is rendered
from a sprite sheet rather than text UI.

## Signals and Cross-Node Communication

Signals are used sparingly and only where object-local logic needs to notify the
board or HUD.

### Defined signals

- `gift.gd`
  - `gift_moved`

- `ice_block.gd`
  - `add_score`

### Active connections

- Each spawned gift connects `gift_moved` to `test.gd::_on_gift_moved()`.
- Each spawned ice block connects `add_score` to `Score.add`.

### Communication style

The project uses a hybrid approach:

- Signals for low-frequency events.
- Direct method calls for push interactions.
- Direct scene-tree references such as `$Score`, `$Music`, and `$JingleBells`
  from `test.gd`.

That tradeoff is reasonable for the current size of the codebase, but it means
`test.gd` is tightly coupled to its child node names.

## Puzzle Completion Logic

The game’s success condition is checked in `test.gd::_on_gift_moved()`.

### What is checked

After any gift finishes moving:

1. The script checks whether all three gifts share the same row.
2. If not, it checks whether all three share the same column.
3. It extracts the relevant coordinate values.
4. It sorts them.
5. It normalizes them relative to the first value.
6. It verifies that the normalized values are sequential.

In practical terms, the three gifts must end up aligned contiguously on a row or
column.

### Success effects

When the condition passes:

- All trees are switched into their `BLING` movement state.
- The background music changes from `JingleBells` to `Music`.
- `1000` points are added to the score.

There is no explicit game-over or scene transition. The game remains in the same
scene and enters a celebratory post-solve state.

## State Management

This project uses small enum-based local state machines rather than a single
global state model.

### By object type

- Gift: `IDLE`, `MOVING`
- Ice block: `IDLE`, `MOVING`, `BREAKING`
- Tree: `IDLE`, `BLING`

Santa does not define an enum, but behaves as if it has two implicit states:

- waiting on a tile
- moving toward the next tile

This is a good fit for a compact arcade/puzzle project because each node only
needs to know its own current transition state.

## Asset and Presentation Layer

The project follows a scene-per-entity structure:

- Each gameplay entity has its own `.tscn` and `.gd` pair.
- Sprites, animations, collision shapes, and audio players are defined in
  scenes.
- Scripts focus on movement, state, and game rules.

Notable presentation details:

- Santa and ice blocks use `AnimatedSprite2D` for directional or destroy
  animations.
- Gifts use a single-frame animated sprite.
- Trees use a sprite sheet with randomized starting frame variation.
- The score is a custom sprite-digit display instead of a UI `Label`.

## Strengths of the Current Architecture

- Very small and easy to reason about.
- Scene-per-entity organization matches Godot conventions.
- Runtime object behavior is localized and readable.
- Signals are used where they add value without over-engineering the project.
- Procedural setup keeps content generation compact.

## Architectural Constraints and Tradeoffs

The current design works well for the project size, but a few constraints are
worth knowing before extending it.

### Positional truth instead of board model

The game infers state from node positions instead of maintaining a dedicated
board representation. That keeps the code simple, but makes features like undo,
path analysis, save/load, replay, or robust solvability checks harder to add.

### Tight coupling in `test.gd`

`test.gd` currently combines:

- level generation
- runtime object registries
- win checking
- music switching
- score bonus dispatch

That is acceptable here, but it is the main place that would grow unwieldy if
more game modes or rules are added.

### Direct node-name dependencies

Some logic depends on fixed child names such as `$Score`, `$Music`, and
`$JingleBells`. Renaming nodes in the editor without updating code will break
those integrations.

### Randomized startup without seed control

Level generation uses randomness directly, so testability and deterministic
reproduction are limited.

## Extension Guidance

If the project grows, the cleanest next refactors would be:

1. Introduce a dedicated board model that maps grid coordinates to occupancy.
2. Split `test.gd` into level generation and game-rule responsibilities.
3. Add an explicit game-state controller for states such as playing, solved, and
   restarting.
4. Centralize audio and scoring orchestration if more event types are added.
5. Add deterministic random seeding for debugging and test scenarios.

For the current scope, the existing architecture is appropriate: small, direct,
and aligned with Godot’s scene-first workflow.
```text
test (Node2D)
|- Background (instance of background.tscn)
|- Santa (instance of santa.tscn)
|- Score (instance of score.tscn)
|- JingleBells (AudioStreamPlayer)
|- Music (AudioStreamPlayer)
|- Tree* (spawned dynamically)
|- IceBlock* (spawned dynamically)
`- Gift* (spawned dynamically)
```

The dynamic children are instantiated by `test.gd` during `_ready()`.
