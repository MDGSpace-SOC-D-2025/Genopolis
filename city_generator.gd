extends Node2D

var points: Array = []
var triangles: Array = []

var rng := RandomNumberGenerator.new()

func randf_range(a: float, b: float) -> float:
	return rng.randf_range(a, b)

func randi_range(a: int, b: int) -> int:
	return rng.randi_range(a, b)

# Poisson Disc Sampling

func sample_biased_angle(angle_spread_deg: float) -> float:
	var base_angles = [0.0, PI / 2.0, PI, 3.0 * PI / 2.0]
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

			var candidate = center + Vector2(cos(angle), sin(angle)) * radius

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

# DELAUNAY TRIANGULATION
func circumcircle_contains(a: Vector2, b: Vector2, c: Vector2, p: Vector2) -> bool:
	var ax = a.x - p.x
	var ay = a.y - p.y
	var bx = b.x - p.x
	var by = b.y - p.y
	var cx = c.x - p.x
	var cy = c.y - p.y

	var det = (ax * ax + ay * ay) * (bx * cy - by * cx) - (bx * bx + by * by) * (ax * cy - ay * cx) + (cx * cx + cy * cy) * (ax * by - ay * bx)

	return det > 0.0

func edge_equal(e1: Array, e2: Array) -> bool:
	return (e1[0] == e2[0] and e1[1] == e2[1]) or \
		   (e1[0] == e2[1] and e1[1] == e2[0])

func delaunay_triangulation(points: Array) -> Array:
	var triangles: Array = []

	var INF = 1000000.0
	var p1 = Vector2(-INF, -INF)
	var p2 = Vector2( INF, -INF)
	var p3 = Vector2(0, INF)

	triangles.append([p1, p2, p3])

	for p in points:
		var polygon: Array = []
		var new_triangles: Array = []

		for t in triangles:
			if circumcircle_contains(t[0], t[1], t[2], p):
				polygon.append([t[0], t[1]])
				polygon.append([t[1], t[2]])
				polygon.append([t[2], t[0]])
			else:
				new_triangles.append(t)

		var boundary: Array = []

		for i in range(polygon.size()):
			var shared = false
			for j in range(polygon.size()):
				if i != j and edge_equal(polygon[i], polygon[j]):
					shared = true
					break
			if not shared:
				boundary.append(polygon[i])

		for e in boundary:
			new_triangles.append([e[0], e[1], p])

		triangles = new_triangles

	var result: Array = []

	for t in triangles:
		if t[0] != p1 and t[0] != p2 and t[0] != p3 and \
		   t[1] != p1 and t[1] != p2 and t[1] != p3 and \
		   t[2] != p1 and t[2] != p2 and t[2] != p3:
			result.append(t)

	return result

# =========================
# GODOT CALLBACKS
# =========================

func _ready():
	print("CityGenerator is running")

	points = poisson_biased(1200, 800, 30.0, 30, 12345, 2)
	triangles = delaunay_triangulation(points)

	queue_redraw()

func _draw():
	# Draw points
	for p in points:
		draw_circle(p, 2.5, Color.WHITE)

	# Draw triangle edges
	for t in triangles:
		draw_line(t[0], t[1], Color.GRAY, 1.0)
		draw_line(t[1], t[2], Color.GRAY, 1.0)
		draw_line(t[2], t[0], Color.GRAY, 1.0)