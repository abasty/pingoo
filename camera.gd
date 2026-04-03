extends Camera2D

@export var game_size = Vector2(800, 848)
var last_viewport_size = Vector2.ZERO

func _ready():
	# Position camera at center of the full designed scene (HUD + board).
	global_position = game_size / 2.0
	make_current()
	update_zoom()
	last_viewport_size = get_viewport().get_visible_rect().size
# end func _ready

func _process(_delta):
	var viewport = get_viewport()
	var current_size = viewport.get_visible_rect().size
	if current_size != last_viewport_size:
		update_zoom()
		last_viewport_size = current_size
	# end if
# end func _process

func update_zoom():
	var viewport = get_viewport()
	var viewport_size = viewport.get_visible_rect().size
	# Keep the full designed scene visible, preserving aspect ratio.
	var fit_scale = minf(viewport_size.x / game_size.x, viewport_size.y / game_size.y)
	# Camera2D uses inverse scaling: lower zoom values make the game appear larger.
	var zoom_scale = 1.0 / fit_scale
	zoom = Vector2(zoom_scale, zoom_scale)
# end func update_zoom
