extends Node2D

var points := []

var rng := RandomNumberGenerator.new()

func randf_range(a: float, b: float) -> float:
	return rng.randf_range(a, b)

func randi_range(a: int, b: int) -> int:
	return rng.randi_range(a, b)

func sample_biased_angle(angle_spread_deg: float) -> float:
	var base_angles = [ 0.0, PI / 2.0, PI, 3.0 * PI / 2.0]

	var base = randi_range(0, 3)
	var spread_rad = deg_to_rad(angle_spread_deg)
	var offset = randf_range(-spread_rad, spread_rad)

	return base_angles[base] + offset

func too_close(p: Vector2, points: Array, min_dist: float) -> bool:
	var min_dist_sq = min_dist * min_dist

	for q in points:
		if p.distance_squared_to(q) < min_dist_sq:
			return true

	return false

func poisson_biased(
	width: int,
	height: int,
	min_dist: float,
	k: int,
	seed: int,
	angle_spread_deg: float
) -> Array:
	
	rng.seed = seed

	var points: Array = []
	var active: Array = []

	# Initial point
	var first = Vector2(
		randf_range(0.0, width),
		randf_range(0.0, height)
	)

	points.append(first)
	active.append(first)

	while active.size() > 0:
		var idx = randi_range(0, active.size() - 1)
		var center: Vector2 = active[idx]
		var found = false

		for i in range(k):
			var angle = sample_biased_angle(angle_spread_deg)
			var radius = randf_range(min_dist, 2.0 * min_dist)

			var candidate = center + Vector2(
				cos(angle),
				sin(angle)
			) * radius

			# Bounds check
			if candidate.x < 0 or candidate.x >= width:
				continue
			if candidate.y < 0 or candidate.y >= height:
				continue

			if not too_close(candidate, points, min_dist):
				points.append(candidate)
				active.append(candidate)
				found = true
				break

		if not found:
			active.remove_at(idx)

	return points


func _ready():
	print("CityGenerator is running")
	points = poisson_biased(1200, 700, 30.0, 30, 12345, 5.0)
	queue_redraw()

func _draw(): for p in points:
	draw_circle(p, 4.0, Color.WHITE)
