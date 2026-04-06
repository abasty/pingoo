extends Node2D

class_name EggIndicator

@export var duration: float = 3.0
var elapsed: float = 0.0

func _ready():
	modulate.a = 0.8  # Semi-transparent

func _process(delta):
	elapsed += delta
	if elapsed >= duration:
		queue_free()
		return

	# Optional: fade out in last 0.5 seconds
	if elapsed > duration - 0.5:
		modulate.a = 0.8 * ((duration - elapsed) / 0.5)
