extends Camera2D

@export var pan_speed: float = 600.0
@export var zoom_step: float = 0.1

@export var min_zoom: float = 1.0
@export var max_zoom: float = 3.0

var dragging := false

func _ready():
	make_current()
	zoom = Vector2(1.0,1.0)

func _process(delta):
	var dir := Vector2.ZERO

	if Input.is_action_pressed("ui_left"):
		dir.x -= 1
	if Input.is_action_pressed("ui_right"):
		dir.x += 1
	if Input.is_action_pressed("ui_up"):
		dir.y -= 1
	if Input.is_action_pressed("ui_down"):
		dir.y += 1

	if dir != Vector2.ZERO:
		position += dir.normalized() * pan_speed * delta

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			zoom -= Vector2(zoom_step, zoom_step)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			zoom += Vector2(zoom_step, zoom_step)

		zoom.x = clamp(zoom.x, min_zoom, max_zoom)
		zoom.y = clamp(zoom.y, min_zoom, max_zoom)

		if event.button_index == MOUSE_BUTTON_MIDDLE:
			dragging = event.pressed

	elif event is InputEventMouseMotion and dragging:
		position -= event.relative * zoom.x
