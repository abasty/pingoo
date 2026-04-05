extends Node

const INITIAL_LIVES: int = 3
const LEVEL_TIME_SECONDS: float = 60.0

var current_level: int = 1
var current_score: int = 0
var current_level_score: int = 0
var has_started_game: bool = false
var player_name: String = "Player"
var lives: int = INITIAL_LIVES
var level_time_left: float = LEVEL_TIME_SECONDS

# Per-level state (reset on level start)
var egg_containers: Array[Vector2] = []  # Positions of 3 blocks containing eggs
var eggs_destroyed: int = 0               # Count of eggs destroyed (0-3)
var eggs_spawned: int = 0                 # Count of eggs that have hatched (0-3)
var next_egg_spawn_time: float = 10.0    # Seconds elapsed until next egg hatches
var last_hatch_time: float = 0.0         # Level time when last egg hatched
var monsters_crushed: int = 0             # Count of monsters crushed by blocks (0-3)
var is_level_running: bool = false        # Whether the level is currently active

func reset_game():
	current_level = 1
	current_score = 0
	current_level_score = 0
	has_started_game = false
	lives = INITIAL_LIVES
	level_time_left = LEVEL_TIME_SECONDS
# end func reset_game

func next_level():
	current_level += 1
# end func next_level

func start_level():
	current_level_score = 0
	level_time_left = LEVEL_TIME_SECONDS
	has_started_game = true
	is_level_running = true
	reset_egg_state()
# end func start_level

func add_score(score: int):
	current_score += score
	current_level_score += score
# end func add_score

func abandon_level():
	current_score -= current_level_score
	if current_score < 0:
		current_score = 0
	# end if
	current_level_score = 0
# end func abandon_level

func lose_life():
	lives -= 1
	if lives < 0:
		lives = 0
	# end if
# end func lose_life

func is_game_over() -> bool:
	return lives <= 0
# end func is_game_over

func reset_egg_state():
	"""Reset egg and monster tracking for a new level."""
	egg_containers.clear()
	eggs_destroyed = 0
	eggs_spawned = 0
	next_egg_spawn_time = 10.0
	last_hatch_time = 0.0
	monsters_crushed = 0
# end func reset_egg_state
