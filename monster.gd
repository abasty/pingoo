extends Node2D

class_name Monster

const TILE_SIZE: int = 40
const MOVE_SPEED: float = 120.0  # pixels/sec
const SMASH_SPEED: float = 50.0   # pixels/sec when smashing through a block

@onready var sprite: AnimatedSprite2D = get_node("AnimatedSprite2D")

var target: Vector2
var _current_speed: float = MOVE_SPEED

var directions = [
	Vector2i.UP,
	Vector2i.DOWN,
	Vector2i.LEFT,
	Vector2i.RIGHT
]

var current_direction: Vector2i = Vector2i.ZERO
var being_pushed: bool = false

func _ready():
	add_to_group("monsters")
	_build_sprite_frames(randi() % 8)
	sprite.play()
	# Ensure the monster is perfectly aligned to the grid to prevent diagonal drift.
	position = _tile_to_world(_world_to_tile(position))
	target = position
	_choose_next_target()

func _build_sprite_frames(color_index: int) -> void:
	# monsters.png: 4 colors × 2 rows = 8 colors
	# Each color block: 3 cols × 4 rows of 40×40px sprites = 120×160px
	# Within each block — row 0: move-down, row 1: move-left, row 2: move-right, row 3: move-up
	var texture: Texture2D = load("res://media/monsters.png")
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	var cx: int = (color_index % 4) * 120  # color column offset
	var cy: int = (color_index >> 2) * 160  # color row offset (0 or 160)
	var anims := [
		[&"move-down",  0],
		[&"move-left",  40],
		[&"move-right", 80],
		[&"move-up",    120],
	]
	for anim in anims:
		var anim_name: StringName = anim[0]
		var row_offset: int = anim[1]
		frames.add_animation(anim_name)
		frames.set_animation_loop(anim_name, true)
		frames.set_animation_speed(anim_name, 8.0)
		for col in range(3):
			var atlas := AtlasTexture.new()
			atlas.atlas = texture
			atlas.region = Rect2(cx + col * 40, cy + row_offset, 40, 40)
			frames.add_frame(anim_name, atlas)
	sprite.sprite_frames = frames
	sprite.animation = &"move-down"
# end func _build_sprite_frames

func _process(delta):
	# Move strictly tile-to-tile: only change direction once a tile destination is reached.
	if not position.is_equal_approx(target):
		var to_target = target - position
		var step = _current_speed * delta
		if to_target.length() <= step:
			position = target
			_current_speed = MOVE_SPEED  # restore normal speed once tile is reached
		else:
			position += to_target.normalized() * step
		# end if
		return
	# end if

	_choose_next_target()

func _choose_next_target() -> void:
	"""Continue straight if free; when changing direction also consider breakable blocks."""
	var current_tile: Vector2i = _world_to_tile(position)

	# Continue in same direction only if the next tile is fully free (no blocks)
	if current_direction != Vector2i.ZERO:
		var next_tile = current_tile + current_direction
		if _is_tile_free(next_tile):
			target = _tile_to_world(next_tile)
			return
		# end if
	# end if

	# Changing direction — include tiles with breakable blocks as candidates
	var candidates: Array = []
	for dir in directions:
		if _is_tile_passable(current_tile + dir):
			candidates.append(dir)
		# end if
	# end for

	if candidates.is_empty():
		current_direction = Vector2i.ZERO
		target = position
		return
	# end if

	current_direction = _pick_direction(candidates, current_tile)
	target = _tile_to_world(current_tile + current_direction)
	_update_animation()
	_smash_block_if_present(current_tile + current_direction)

func _pick_direction(candidates: Array, current_tile: Vector2i) -> Vector2i:
	"""2/3 chance: pick the direction that brings the monster closest to Santa.
	   1/3 chance: pick randomly among all passable candidates."""
	var santa = get_parent().get_node_or_null("Santa")
	if santa == null or randi() % 3 == 0:
		return candidates[randi() % candidates.size()]
	# end if

	var santa_tile := _world_to_tile(santa.position)
	var best_dir: Vector2i = candidates[randi() % candidates.size()]
	var best_dist: float = INF

	for dir in candidates:
		var dist := float((current_tile + dir).distance_squared_to(santa_tile))
		if dist < best_dist:
			best_dist = dist
			best_dir = dir
		# end if
	# end for

	return best_dir
# end func _pick_direction

func _update_animation() -> void:
	"""Play the animation matching the current movement direction."""
	if sprite == null:
		return
	# end if
	if current_direction == Vector2i.ZERO:
		sprite.stop()
		return
	# end if
	if current_direction.x < 0:
		sprite.animation = &"move-left"
	elif current_direction.x > 0:
		sprite.animation = &"move-right"
	elif current_direction.y < 0:
		sprite.animation = &"move-up"
	else:
		sprite.animation = &"move-down"
	# end if
	sprite.play()
# end func _update_animation

func _smash_block_if_present(tile_pos: Vector2i) -> void:
	"""Destroy the ice block on this tile (if any) and slow the monster."""
	var block = _find_block_at_tile(tile_pos)
	if block != null:
		block.hatch()
		_current_speed = SMASH_SPEED
	# end if
# end func _smash_block_if_present

func _find_block_at_tile(tile_pos: Vector2i):
	"""Return the ice block node at tile_pos, or null."""
	var world_pos := _tile_to_world(tile_pos)
	for block in get_tree().get_nodes_in_group("ice_blocks"):
		if block.position.distance_to(world_pos) < 1.0:
			return block
		# end if
	# end for
	return null
# end func _find_block_at_tile

func _is_tile_passable(tile_pos: Vector2i) -> bool:
	"""Check if a tile can be entered (trees and gifts block; ice blocks are smashable)."""
	if tile_pos.x < 0 or tile_pos.x >= 20 or tile_pos.y < 0 or tile_pos.y >= 20:
		return false
	# end if
	var world_pos := _tile_to_world(tile_pos)
	for tree in get_tree().get_nodes_in_group("trees"):
		if tree.position.distance_to(world_pos) < 1.0:
			return false
		# end if
	# end for
	for gift in get_tree().get_nodes_in_group("gifts"):
		if gift.position.distance_to(world_pos) < 1.0:
			return false
		# end if
	# end for
	return true
# end func _is_tile_passable

func _is_tile_free(tile_pos: Vector2i) -> bool:
	"""Check if a tile contains no blocking entities."""
	# Guard against out-of-bounds
	if tile_pos.x < 0 or tile_pos.x >= 20 or tile_pos.y < 0 or tile_pos.y >= 20:
		return false
	# end if

	var world_pos = _tile_to_world(tile_pos)

	# Check for trees
	var trees = get_tree().get_nodes_in_group("trees")
	for tree in trees:
		if tree.position.distance_to(world_pos) < 1.0:
			return false
		# end if
	# end for

	# Check for ice blocks
	var blocks = get_tree().get_nodes_in_group("ice_blocks")
	for block in blocks:
		if block.position.distance_to(world_pos) < 1.0:
			return false
		# end if
	# end for

	# Check for gifts
	var gifts = get_tree().get_nodes_in_group("gifts")
	for gift in gifts:
		if gift.position.distance_to(world_pos) < 1.0:
			return false
		# end if
	# end for

	return true

func get_tile_position() -> Vector2:
	"""Return the grid tile coordinates."""
	return Vector2(_world_to_tile(position))

func _world_to_tile(world_pos: Vector2) -> Vector2i:
	return Vector2i(roundi(world_pos.x / TILE_SIZE), roundi(world_pos.y / TILE_SIZE))

func _tile_to_world(tile_pos: Vector2i) -> Vector2:
	return Vector2(tile_pos.x * TILE_SIZE, tile_pos.y * TILE_SIZE)
