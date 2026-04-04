extends Control

const AMBIENT_FLAKE_TARGET = 180
const SPAWN_RATE = 42.0

var rng = RandomNumberGenerator.new()
var flakes = []
var spawn_accumulator = 0.0

func _ready():
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	rng.randomize()
# end func _ready

func setup(_buttons: Array):
	# Kept for compatibility with existing menu call site.
	# No button interaction or accumulation behavior.
	queue_redraw()
# end func setup

func _process(delta):
	spawn_accumulator += delta * SPAWN_RATE
	while spawn_accumulator >= 1.0 and _count_ambient_flakes() < AMBIENT_FLAKE_TARGET:
		spawn_accumulator -= 1.0
		_spawn_flake(Vector2(rng.randf_range(0.0, size.x), rng.randf_range(-24.0, 0.0)))
	# end while

	_update_flakes(delta)
	queue_redraw()
# end func _process

func _draw():
	for flake in flakes:
		draw_circle(flake.position, flake.radius, Color(1.0, 1.0, 1.0, flake.alpha))
	# end for
# end func _draw

func _spawn_flake(start_position: Vector2):
	flakes.append({
		"position": start_position,
		"velocity": Vector2(rng.randf_range(-26.0, 26.0), rng.randf_range(42.0, 96.0)),
		"radius": rng.randf_range(1.2, 3.8),
		"alpha": rng.randf_range(0.45, 0.98)
	})
# end func _spawn_flake

func _update_flakes(delta):
	var viewport_size = get_viewport_rect().size
	var alive_flakes = []
	for flake in flakes:
		flake.position += flake.velocity * delta
		flake.velocity.x += sin(flake.position.y * 0.02) * 3.5 * delta
		if flake.position.y <= viewport_size.y + 20.0 and flake.position.x >= -30.0 and flake.position.x <= viewport_size.x + 30.0:
			alive_flakes.append(flake)
		# end if
	# end for
	flakes = alive_flakes
# end func _update_flakes

func _count_ambient_flakes() -> int:
	return flakes.size()
# end func _count_ambient_flakes
