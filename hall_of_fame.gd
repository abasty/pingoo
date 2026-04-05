extends Node

const SAVE_PATH = "user://hall_of_fame.cfg"
const MAX_TOP_SCORES = 10

var top_scores: Array = []
var level_highscores: Dictionary = {}

func _ready():
	_load_data()
# end func _ready

func get_top_scores() -> Array:
	return top_scores.duplicate(true)
# end func get_top_scores

func get_level_highscore(level: int) -> int:
	return int(level_highscores.get(str(level), 0))
# end func get_level_highscore

func get_rank_for_score(score: int, reached_level: int) -> int:
	if score <= 0:
		return 0
	# end if

	var rank = 1
	for entry in top_scores:
		var entry_score = int(entry.get("score", 0))
		var entry_level = int(entry.get("level", 0))
		if score > entry_score or (score == entry_score and reached_level >= entry_level):
			break
		# end if
		rank += 1
	# end for

	if rank > MAX_TOP_SCORES:
		return 0
	# end if
	return rank
# end func get_rank_for_score

func submit_score(player_name: String, score: int, reached_level: int):
	if score <= 0:
		return
	# end if

	top_scores.append({
		"name": player_name.strip_edges() if not player_name.strip_edges().is_empty() else "Player",
		"score": score,
		"level": reached_level
	})
	top_scores.sort_custom(_sort_scores_desc)
	if top_scores.size() > MAX_TOP_SCORES:
		top_scores.resize(MAX_TOP_SCORES)
	# end if
	_save_data()
# end func submit_score

func update_level_highscore(level: int, score: int):
	if score <= 0:
		return
	# end if

	var key = str(level)
	var previous = int(level_highscores.get(key, 0))
	if score > previous:
		level_highscores[key] = score
		_save_data()
	# end if
# end func update_level_highscore

func clear_all_scores():
	top_scores.clear()
	level_highscores.clear()
	_save_data()
# end func clear_all_scores

func _sort_scores_desc(a: Dictionary, b: Dictionary) -> bool:
	if int(a.get("score", 0)) == int(b.get("score", 0)):
		return int(a.get("level", 0)) > int(b.get("level", 0))
	# end if
	return int(a.get("score", 0)) > int(b.get("score", 0))
# end func _sort_scores_desc

func _load_data():
	top_scores.clear()
	level_highscores.clear()

	var config = ConfigFile.new()
	var err = config.load(SAVE_PATH)
	if err != OK:
		return
	# end if

	var raw_scores = config.get_value("hall_of_fame", "top_scores", [])
	if raw_scores is Array:
		for entry in raw_scores:
			if entry is Dictionary and entry.has("name") and entry.has("score") and entry.has("level"):
				top_scores.append({
					"name": str(entry["name"]),
					"score": int(entry["score"]),
					"level": int(entry["level"])
				})
			# end if
		# end for
	# end if
	top_scores.sort_custom(_sort_scores_desc)
	if top_scores.size() > MAX_TOP_SCORES:
		top_scores.resize(MAX_TOP_SCORES)
	# end if

	var raw_level_scores = config.get_value("hall_of_fame", "level_highscores", {})
	if raw_level_scores is Dictionary:
		for level_key in raw_level_scores.keys():
			level_highscores[str(level_key)] = int(raw_level_scores[level_key])
		# end for
	# end if
# end func _load_data

func _save_data():
	var config = ConfigFile.new()
	config.set_value("hall_of_fame", "top_scores", top_scores)
	config.set_value("hall_of_fame", "level_highscores", level_highscores)
	config.save(SAVE_PATH)
# end func _save_data
