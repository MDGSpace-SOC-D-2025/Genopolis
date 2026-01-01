extends Camera2D

@export var pan_speed := 500.0
@export var zoom_speed := 0.1


func _process(delta):
	var move = Vector2.ZERO

	if Input.is_action_pressed("ui_left"):
		move.x -= 1
	if Input.is_action_pressed("ui_right"):
		move.x += 1
	if Input.is_action_pressed("ui_up"):
		move.y -= 1
	if Input.is_action_pressed("ui_down"):
		move.y += 1

	position += move.normalized() * pan_speed * delta

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom *= 1.0 - zoom_speed
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom *= 1.0 + zoom_speed
