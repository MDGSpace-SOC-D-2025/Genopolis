extends Node2D

var points: Array = []
var triangles: Array = []

var edges: Array = []
var mst_edges: Array = []
var secondary_edges: Array = []

@export var city_width: int = 1200
@export var city_height: int = 800
@export var min_radius: int = 30
@export var angleSpreadDeg: float = 2.0
@export var poisson_max = 1.6

var rng := RandomNumberGenerator.new()

# all polygons within x:(0,1500) and y:(0,1500)
var city_polygons := [
	[Vector2(140, 180),Vector2(620, 60),Vector2(1180, 220),Vector2(1460, 520),
	Vector2(1320, 980),Vector2(920, 1380),Vector2(360, 1240),Vector2(80, 620)],

	[Vector2(300, 80),Vector2(900, 140),Vector2(1420, 380),Vector2(1380, 760),
	Vector2(1100, 1220),Vector2(600, 1460),Vector2(180, 1020),Vector2(120, 360)],

	[Vector2(60, 420),Vector2(420, 120),Vector2(980, 80),Vector2(1400, 340),
	Vector2(1480, 780),Vector2(1040, 1400),Vector2(520, 1300),Vector2(120, 820)],

	[Vector2(260, 60),Vector2(860, 100),Vector2(1320, 260),Vector2(1480, 620),
	Vector2(1280, 1040),Vector2(740, 1380),Vector2(240, 1160),Vector2(120, 380)],

	[Vector2(100, 260),Vector2(560, 80),Vector2(1040, 160),Vector2(1420, 480),
	Vector2(1460, 920),Vector2(980, 1460),Vector2(420, 1340),Vector2(60, 720)],

	[Vector2(220, 120),Vector2(740, 60),Vector2(1260, 200),Vector2(1400, 520),
	Vector2(1300, 860),Vector2(980, 1250),Vector2(420, 1200),Vector2(100, 620)],

	[Vector2(80, 520),Vector2(360, 160),Vector2(900, 100),Vector2(1380, 300),
	Vector2(1500, 660),Vector2(1120, 1480),Vector2(520, 1400),Vector2(120, 860)],

	[Vector2(320, 180),Vector2(1140, 260),Vector2(1480, 460),
	Vector2(1420, 860),Vector2(1000, 1320),Vector2(460, 1280),Vector2(290, 1120), Vector2(120, 620)],

	[Vector2(240, 160),Vector2(860, 100),Vector2(1360, 240),Vector2(1500, 560),
	Vector2(1380, 980),Vector2(860, 1400),Vector2(320, 1320),Vector2(100, 760)],

	[Vector2(320, 120),Vector2(740, 80),Vector2(1180, 180),Vector2(1460, 420),
	Vector2(1500, 820),Vector2(1080, 1380),Vector2(480, 1360),Vector2(320, 1160),Vector2(160, 620)]
]

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
	min_dist: float,
	k: int,
	angle_spread_deg: float
) -> Array:
	
	var points: Array = []
	var active: Array = []

	var polygon = city_polygons[randi_range(0,9)]
	var first = Vector2(750, 750)

	points.append(first)
	active.append(first)

	while active.size() > 0:
		var idx = randi_range(0, active.size() - 1)
		var center: Vector2 = active[idx]
		var found = false

		for i in range(k):
			var angle = sample_biased_angle(angle_spread_deg)
			var radius = randf_range(min_dist, poisson_max * min_dist)

			var candidate = center + Vector2(cos(angle), sin(angle)) * radius

			if not Geometry2D.is_point_in_polygon(candidate, polygon):
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

func make_edge_key(u: int, v: int) -> String:
	if u > v:
		var tmp = u
		u = v
		v = tmp
	return str(u) + "_" + str(v)

func extract_clean_edges(points: Array, triangles: Array) -> Array:
	var edge_count := {}
	for t in triangles:
		var i1 = points.find(t[0])
		var i2 = points.find(t[1])
		var i3 = points.find(t[2])

		var k1 = make_edge_key(i1, i2)
		var k2 = make_edge_key(i2, i3)
		var k3 = make_edge_key(i3, i1)

		edge_count[k1] = edge_count.get(k1, 0) + 1
		edge_count[k2] = edge_count.get(k2, 0) + 1
		edge_count[k3] = edge_count.get(k3, 0) + 1

	var edges: Array = []

	for key in edge_count.keys():
		if edge_count[key] == 2:
			var parts = key.split("_")
			var u = int(parts[0])
			var v = int(parts[1])
			var wt = points[u].distance_to(points[v])
			edges.append([u, v, wt])

	return edges

func make_set(n: int) -> Dictionary:
	var parent := []
	var rank := []
	for i in range(n):
		parent.append(i)
		rank.append(0)
	return { "parent": parent, "rank": rank }

func dsu_find(parent: Array, node: int) -> int:
	if parent[node] == node:
		return node
	parent[node] = dsu_find(parent, parent[node])
	return parent[node]

func union_set(u: int, v: int, parent: Array, rank: Array) -> void:
	u = dsu_find(parent, u)
	v = dsu_find(parent, v)

	if rank[u] < rank[v]:
		parent[u] = v
	elif rank[u] > rank[v]:
		parent[v] = u
	else:
		parent[v] = u
		rank[u] += 1

func kruskal_mst(edges: Array, n: int) -> Array:
	edges.sort_custom(func(a, b): return a[2] < b[2])

	var dsu = make_set(n)
	var parent = dsu["parent"]
	var rank = dsu["rank"]

	var mst: Array = []

	for e in edges:
		var u = e[0]
		var v = e[1]
		var w = e[2]

		var pu = dsu_find(parent, u)
		var pv = dsu_find(parent, v)

		if pu != pv:
			mst.append(e)
			union_set(pu, pv, parent, rank)

	return mst

# calculate average length of MST edges.
func mst_average_weight(mst_edges: Array) -> float:
	var sum := 0.0
	for e in mst_edges:
		sum += e[2]
	return sum / mst_edges.size()

func extract_secondary_edges(mst_edges: Array, edges: Array, points: Array) -> Array:
	
	var avg := mst_average_weight(mst_edges)
	var secondary_edges: Array = []

	for e in edges:
		var u: Vector2 = points[e[0]]
		var v: Vector2 = points[e[1]]

		if u.distance_to(v) < 1.6 * avg:
			secondary_edges.append(e)

	return secondary_edges

func extract_secondary_directional(mst_edges: Array, edges: Array, points: Array) -> Array:

	var base_secondary := extract_secondary_edges(mst_edges, edges, points)
	var result: Array = []
	var angle_threshold := deg_to_rad(25.0)

	for e in base_secondary:
		var u: Vector2 = points[e[0]]
		var v: Vector2 = points[e[1]]

		var dx = abs(v.x - u.x)
		var dy = abs(v.y - u.y)

		var angle = atan2(dy, dx)

		if angle < angle_threshold or abs(angle - PI / 2.0) < angle_threshold:
			result.append(e)

	return result


func _ready():
	print("CityGenerator is running")

	points = poisson_biased(min_radius, 30, angleSpreadDeg)
	triangles = delaunay_triangulation(points)
	edges = extract_clean_edges(points, triangles)
	mst_edges = kruskal_mst(edges, points.size())
	secondary_edges = extract_secondary_directional(mst_edges, edges, points)

	queue_redraw()

func _draw():
	for p in points:
		draw_circle(p, 2.5, Color.WHITE)

	if(show_roads):
		for e in secondary_edges:
			draw_line(points[e[0]], points[e[1]], Color.GRAY, 1)
		for e in mst_edges:
			draw_line(points[e[0]], points[e[1]], Color.WHITE, 3)

func _on_regenerate_button_pressed():
	points = poisson_biased( min_radius, 30, angleSpreadDeg)
	triangles = delaunay_triangulation(points)
	edges = extract_clean_edges(points, triangles)
	mst_edges = kruskal_mst(edges, points.size())
	secondary_edges = extract_secondary_directional(mst_edges, edges, points)
	queue_redraw()

var show_roads := true

func _on_toggle_button_pressed():
	show_roads = !show_roads
	queue_redraw()