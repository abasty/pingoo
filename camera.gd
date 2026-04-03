extends Camera2D

@export var game_size = 800
var last_viewport_size = Vector2.ZERO

func _ready():
	# Position camera at center of game
	global_position = Vector2(game_size / 2.0, game_size / 2.0)
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
	# Camera2D uses inverse scaling: lower zoom values make the game appear larger.
	var zoom_scale = float(game_size) / minf(viewport_size.x, viewport_size.y)
	zoom = Vector2(zoom_scale, zoom_scale)
# end func update_zoom
