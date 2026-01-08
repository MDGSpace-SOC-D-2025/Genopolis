extends Camera2D

@export var pan_speed: float = 600.0
@export var zoom_step: float = 0.1

@export var city_width = 1200
@export var city_height = 800

@export var min_zoom: float = 0.6
@export var max_zoom: float = 3.0

var dragging := false

func _ready():
	position = Vector2(200, 300)
	make_current()
	zoom = Vector2(0.6, 0.6)

func _process(delta):
	var dir := Vector2.ZERO

	if Input.is_action_pressed("ui_left") and position.x > -1200:
		dir.x -= 1
	if Input.is_action_pressed("ui_right") and position.x < 1500:
		dir.x += 1
	if Input.is_action_pressed("ui_up") and position.y > -600:
		dir.y -= 1
	if Input.is_action_pressed("ui_down") and position.y < 1200:
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
		if position.x > 1500 or position.x < -1200 or position.y < -600 or position.y > 1200:
			position += event.relative * zoom.x