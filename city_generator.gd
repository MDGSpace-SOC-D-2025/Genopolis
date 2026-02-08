extends Node2D

var polygon = []
var points: Array = []
var triangles: Array = []

var edges: Array = []
var mst_edges: Array = []
var secondary_edges: Array = []
var all_edges: Array = []
var temp_blocks: Array = []
var city_blocks : Array = []
var blocks: Array = []
var blocks_area: Array = []
var building_points: Array = []

@export var min_radius: int = 20
@export var angleSpreadDeg: float = 2.0
@export var poisson_max = 1.6

var rng := RandomNumberGenerator.new()
var height_noise = FastNoiseLite.new()

var STV = 1e5;
var p1 = Vector2(-STV, -STV)
var p2 = Vector2(STV, -STV)
var p3 = Vector2(0, STV)

var cell_size : float
var grid := {}   # Dictionary<Vector2i, Array[int]>

var road_width = 2.0

var min_building_height = 2.0
var max_building_height := 0.0
@export var max_height_multiplier := 10.0

var total_block_area := 0.0
var avg_area: float = 0.0
var a = 0
var b = 0
var c = 0
var d = 0

# Note: If you have a list of lists(2D array), but you only wanna loop over the first column of the 2D array
# for i in (row[0] for row in arr):
# OR
# first_column = [row[0] for row in arr]
# for i in first_column:
#     do_something(i)
# But this only works in pyhton, for godot, loop over the whole thing.

# all polygons within x:(0,1500) and y:(0,1500)
var city_polygons := [
	[Vector2(140, 180),Vector2(620, 60),Vector2(1180, 220),Vector2(1460, 520),
	Vector2(1320, 980),Vector2(920, 1380),Vector2(360, 1240),Vector2(80, 620)],

	[Vector2(300, 80),Vector2(900, 140),Vector2(1420, 380),Vector2(1380, 760),
	Vector2(1100, 1220),Vector2(850, 1300),Vector2(550, 1250),Vector2(180, 1020),Vector2(120, 360)],

	[Vector2(90, 420),Vector2(420, 120),Vector2(980, 80),Vector2(1400, 340),
	Vector2(1480, 780),Vector2(1040, 1200),Vector2(520, 1300),Vector2(120, 820)],

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

@warning_ignore("shadowed_variable")
func randf_range(a: float, b: float) -> float:
	return rng.randf_range(a, b)

@warning_ignore("shadowed_variable")
func randi_range(a: int, b: int) -> int:
	return rng.randi_range(a, b)

# Poisson Disc Sampling

func poisson_angle(angle_spread_deg: float) -> float:
	var base_angles = [0.0, PI / 2.0, PI, 3.0 * PI / 2.0]
	var base = randi_range(0, 3)
	var spread_rad = deg_to_rad(angle_spread_deg)
	var offset = randf_range(-spread_rad, spread_rad)
	return base_angles[base] + offset

@warning_ignore("shadowed_variable")
func too_close(p: Vector2, points: Array, min_dist: float) -> bool:
	var min_dist_sq = min_dist * min_dist
	for q in points:
		if p.distance_squared_to(q) < min_dist_sq:
			return true
	return false

func poisson_disc_sampling_biased(min_dist: float, k: int,angle_spread_deg: float) -> Array:
	
	var points: Array = []
	var active: Array = []

	var first = Vector2(750, 750)

	points.append(first)
	active.append(first)

	while active.size() > 0:
		var idx = randi_range(0, active.size() - 1)
		var center: Vector2 = active[idx]
		var found = false

		for i in range(k):
			var angle = poisson_angle(angle_spread_deg)
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

func is_building_point_valid(pts: Array, block: Array, candidate: Array) -> bool:
	
	for point in pts:
		if candidate[0] == point[0]:
			continue
		var dist = sqrt( (candidate[0].x - point[0].x)**2 + (candidate[0].y - point[0].y)**2 )
		if candidate[4] + point[4] > dist:
			return false
	
	for i in range(0, block[0].size() - 1):
		var u = block[0][i]
		var v = block[0][i+1]
		var w = Geometry2D.get_closest_point_to_segment(candidate[0], u, v)
		var dist = candidate[0].distance_to(w)
		if dist < (road_width / 2) + candidate[4]:
			return false
	var w = Geometry2D.get_closest_point_to_segment(candidate[0], block[0][block[0].size()-1], block[0][0])
	var dist = candidate[0].distance_to(w)
	if dist < (road_width / 2) + candidate[4]:
		return false
	
	return true

func poisson_DS_building_placement(blocks: Array, height_noise: FastNoiseLite) -> Array:
	
	var pts := []
	var pnts := []
	var active := []
	
	var sum_x = 0.0
	var sum_y = 0.0
	
	for block in blocks:
		print("block")
		pnts = []
		active = []
		
		sum_x = 0.0
		sum_y = 0.0
		
		for i in block[0]:
			sum_x += i.x
			sum_y += i.y
			
		var first_position = Vector2(sum_x / block[0].size(), sum_y / block[0].size())
		var first_height = get_building_height(first_position)
		var first_base: Vector3 = get_building_base(first_height)
		pnts.append([first_position, first_height, first_base.x, first_base.y, first_base.z])
		pts.append([first_position, first_height, first_base.x, first_base.y, first_base.z])
		active.append([first_position, first_height, first_base.x, first_base.y, first_base.z])
		
		while active.size()>0:
			var idx = randi_range(0, active.size() - 1)
			var center: Vector2 = active[idx][0]
			var found = false
			
			for i in range(10):
				var angle = poisson_angle(2)
				var radius = randi_range(65, 75)
				var candidate_position = center + Vector2(cos(angle), sin(angle)) * radius
			
				if not Geometry2D.is_point_in_polygon(candidate_position, block[0]):
					pass
				else:
					var height = get_building_height(candidate_position)
					var base: Vector3 = get_building_base(height)
					var candidate = [candidate_position, height, base.x, base.y, base.z]
					# (position, height, width, length, d) 
			
					if is_building_point_valid(pnts, block, candidate):
						print(candidate)
						pnts.append(candidate)
						pts.append(candidate)
						active.append(candidate)
						found = true
						break
			
			if not found:
				active.remove_at(idx)
	return pts

func is_point_valid(edges: Array, points: Array, candidate: Array, polygon: Array) -> bool:
	if not Geometry2D.is_point_in_polygon(candidate[0], polygon):
		return false
	
	for point in points:
		if candidate[0] == point[0]:
			continue
		var dist = candidate[0].distance_to(point[0])
		if candidate[4] + point[4] > dist:
			return false
	
	for e in edges:
		var w = Geometry2D.get_closest_point_to_segment(candidate[0], e[0], e[1])
		var dist = candidate[0].distance_to(w)
		if dist < candidate[4] + (road_width / 2):
			return false
	
	return true

func poisson_DS_buildings(edges: Array, height_noise: FastNoiseLite):
	var points = []
	var active = []
	var counter = 0
	
	while counter < 50:
		var first_position = Vector2(randf_range(500, 1000), randf_range(500, 1000))
		var first_height = get_building_height(first_position)
		var first_base: Vector3 = get_building_base(first_height)
		var first = [first_position, first_height, first_base.x, first_base.y, first_base.z]
		if is_point_valid(edges, points, first, polygon):
			points.append(first)
			active.append(first)
			counter += 1
	
	while active.size()>0:
		var idx = randi_range(0, active.size() - 1)
		var center: Vector2 = active[idx][0]
		var found = false
		var search_other_blocks = true
		
		for i in range(15):
			var angle = poisson_angle(2)
			var radius = randi_range(6, 10)
			var candidate_position = center + Vector2(cos(angle), sin(angle)) * radius
			var height = get_building_height(candidate_position)
			var base: Vector3 = get_building_base(height)
			var candidate = [candidate_position, height, base.x, base.y, base.z]
			
			if is_point_valid(edges, points, candidate, polygon):
				points.append(candidate)
				active.append(candidate)
				found = true
				search_other_blocks = false
				break
		
		if search_other_blocks:
			for j in range(20):
				var angle = poisson_angle(2)
				var radius = randi_range(15, 30)
				var candidate_position = center + Vector2(cos(angle), sin(angle)) * radius
				var height = get_building_height(candidate_position)
				var base: Vector3 = get_building_base(height)
				var candidate = [candidate_position, height, base.x, base.y, base.z]
			
				if is_point_valid(edges, points, candidate, polygon):
					points.append(candidate)
					active.append(candidate)
					found = true
					break
		
		if not found:
			active.remove_at(idx)
	
	return points

func cell_of(pos: Vector2) -> Vector2i:
	return Vector2i(floor(pos.x / cell_size), floor(pos.y / cell_size))
	# which cell the building belongs to

func insert_building(b: Array, buildings: Array, active: Array) -> void:
	
	var c = cell_of(b[0])
	if not grid.has(c):
		grid[c] = []
	grid[c].append(buildings.size())
	buildings.append(b)
	active.append(b)

func nearby_buildings(pos: Vector2, buildings: Array) -> Array:
	var result := []
	var c = cell_of(pos)
	for dx in [-1, 0, 1]:
		for dy in [-1, 0, 1]:
			var k = c + Vector2i(dx, dy)
			if grid.has(k):
				for idx in grid[k]:
					result.append(buildings[idx])
	return result

func is_valid_building(candidate, polygon: Array, edges: Array, buildings: Array) -> bool:

	for b in nearby_buildings(candidate[0], buildings):
		if candidate[0].distance_to(b[0]) < candidate[1] + b[1]:
			return false

	for e in edges:
		var w = Geometry2D.get_closest_point_to_segment(candidate[0], e[0], e[1])
		if candidate[0].distance_to(w) < candidate[1] + (road_width * 0.5):
			return false

	return true

func poisson_buildings(polygon: Array, edges: Array) -> Array:

	var buildings := []
	var active := []

	cell_size = max_building_height
	grid.clear()

	var seed_attempts = 0
	while buildings.size() < 5 and seed_attempts < 2000:
		seed_attempts += 1

		var pos = Vector2(randf_range(0, 1500), randf_range(0, 1500))

		if not Geometry2D.is_point_in_polygon(pos, polygon):
			continue

		var h = get_building_height(pos)
		var base = get_building_base(h)

		var cand = [pos, base.z, h, base.x, base.y]
		# [position, d, height, width, length]
		if is_valid_building(cand, polygon, edges, buildings):
			insert_building(cand, buildings, active)

	var k = 20
	while active.size() > 0:
		var idx = randi_range(0, active.size() - 1)
		var center = active[idx]
		var found = false

		for i in range(k):
			var angle = randf_range(0, 2 * 3.14159)
			var r = randf_range(center[1], 2.2 * center[1])
			var pos = center[0] + Vector2(cos(angle), sin(angle)) * r

			var h = get_building_height(pos)
			var base = get_building_base(h)

			var cand = [pos, base.z, h, base.x, base.y]
			if is_valid_building(cand, polygon, edges, buildings):
				insert_building(cand, buildings, active)
				found = true
				break

		if not found:
			active.remove_at(idx)

	return buildings

# DELAUNAY TRIANGULATION
func is_super_vertex(p: Vector2) -> bool:
	return (p.y == -STV or p.y == STV)

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
		if not is_super_vertex(t[0]) and not is_super_vertex(t[1]) and not is_super_vertex(t[2]):
			result.append(t)

	return result

func make_edge_key(u: int, v: int) -> String:
	if u > v:
		var tmp = u
		u = v
		v = tmp
	return str(u) + "_" + str(v)

func extract_edges_from_delaunay(points: Array, triangles: Array) -> Array:
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

func makeSet(parent: Array, rank: Array, n: int):
	for i in range(n):
		parent[i] = i
		rank[i] = 0

func findParent(parent: Array, node: int) -> int:
	if parent[node] == node:
		return node
	parent[node] = findParent(parent, parent[node])
	return parent[node]


func unionSet(u: int, v: int, parent: Array, rank: Array):
	u = findParent(parent, u)
	v = findParent(parent, v)

	if rank[u] < rank[v]:
		parent[u] = v
	elif rank[u] > rank[v]:
		parent[v] = u
	else:
		parent[v] = u
		rank[u] += 1


func minimumSpanningTree(edges: Array, n: int) -> Array:
	edges.sort_custom(func(a, b): return a[2] < b[2])

	var parent := []
	var rank := []

	parent.resize(n)
	rank.resize(n)

	makeSet(parent, rank, n)

	var mstEdges := []

	for i in range(edges.size()):
		var u = int(edges[i][0])
		var v = int(edges[i][1])
		var wt = edges[i][2]

		var pu = findParent(parent, u)
		var pv = findParent(parent, v)

		if pu != pv:
			mstEdges.append([float(u), float(v), wt])
			unionSet(pu, pv, parent, rank)

	return mstEdges

func extract_mst_directional(mst_edges: Array) -> Array:

	var result: Array = []
	var angle_threshold := deg_to_rad(25.0)

	for e in mst_edges:
		var u: Vector2 = points[e[0]]
		var v: Vector2 = points[e[1]]

		var dx = abs(v.x - u.x)
		var dy = abs(v.y - u.y)

		var angle = atan2(dy, dx)

		if angle <= angle_threshold or abs(angle - PI / 2.0) <= angle_threshold:
			result.append(e)

	return result

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
		if e[2] < 1.6 * avg:
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

		if angle <= angle_threshold or abs(angle - PI / 2.0) <= angle_threshold:
			result.append(e)

	return result
	
func union_edges(points: Array, secondary_edges: Array, mst_edges: Array, is_directed: bool) -> Array:
	var all_edges = []

	for e in secondary_edges:
		all_edges.append([points[e[0]], points[e[1]], e[2]])

	for e in mst_edges:
		if not all_edges.has(e):
			all_edges.append([points[e[0]], points[e[1]], e[2]])
	
	if not is_directed:
		return all_edges

	var directed_edges := []
	for e in all_edges:
		directed_edges.append([points[e[0]], points[e[1]], e[2]])
		directed_edges.append([points[e[1]], points[e[0]], e[2]])
	
	return directed_edges

func remove_singular_vertices(all_edges: Array) -> Array:
	var result = []
	var counter = {}
	
	for e in all_edges:
		var u = int(e[0])
		var v = int(e[1])
		if not counter.has(u):
			counter[u] = 1
		else:
			counter[u] += 1
		
		if not counter.has(v):
			counter[v] = 1
		else:
			counter[v] += 1
	
	for e in all_edges:
		if counter[int(e[0])] > 3 and counter[int(e[1])] > 3:
			result.append(e)
	
	return result

func build_adjacency(points: Array, edges: Array) -> Dictionary:
	var adj := {}

	# adjacency list
	for i in range(points.size()):
		adj[i] = []

	# add neighbors
	for e in edges:
		var u = e[0]
		var v = e[1]
		# adjacency list has integer keys(when initialising), so when doing adj[u].append(),
		# u also needs to be an integer, that's why we do type conversion; otherwise error
		adj[u].append(v)
		adj[v].append(u)

	# sort neighbors by angle, sort them anti clockwise
	for u in adj.keys():
		var neighbours = adj[u]
		var count = neighbours.size()

		for i in range(count):
			for j in range(i + 1, count):
				var a = neighbours[i]
				var b = neighbours[j]

				var va = points[a] - points[u]
				var vb = points[b] - points[u]

				var angle_a = atan2(va.y, va.x)
				var angle_b = atan2(vb.y, vb.x)

				if angle_a > angle_b:
					var temp = neighbours[i]
					neighbours[i] = neighbours[j]
					neighbours[j] = temp

		adj[u] = neighbours

	return adj

func make_directed_key(u: int, v: int) -> String:
	return str(u) + "->" + str(v)

func area_block(block : Array) -> float:
	var result = 0.0
	var s = block.size()
	for i in range(0, s - 1):
		var u = block[i]
		var v = block[i+1]
		result += (u.x * v.y) - (v.x * u.y)
		# print("(", u.x, ",", u.y, ") ", "(", v.x, ",", v.y, ") " )
	result += ( ( block[0].x * block[s-1].y) - (block[0].y * block[s-1].x) )
	result = abs(result) * 0.5
	total_block_area += result
	return result
	
	# on average, 64% blocks are small, 25% are medium, 10 percent are large, 1% are very large
	
func extract_blocks(points: Array, edges: Array) -> Array:
	var adj = build_adjacency(points, edges)
	var used : Dictionary = {}
	var blocks := []

	# mark all directed edges as unused
	for e in edges:
		var u = e[0]
		var v = e[1]
		used[make_directed_key(u, v)] = false

	for e in edges:
		var start_u = e[0]
		var start_v = e[1]
		var start_key = make_directed_key(start_u, start_v)

		if used[start_key]:
			continue

		var block := []
		var u = start_u
		var v = start_v

		while true:
			used[make_directed_key(u, v)] = true
			block.append(points[u])

			var neighbours = adj[v]
			var idx = neighbours.find(u)

			var next_idx
			if idx == 0:
				next_idx = neighbours.size() - 1
			else:
				next_idx = idx - 1

			var w = neighbours[next_idx]
			u = v
			v = w

			if u == start_u and v == start_v:
				break

		# discard outer face by size heuristic
		if block.size() >= 3 and block.size() < 30:
			blocks.append([block, area_block(block)])

	return blocks
	
func classfiy_blocks_by_area(blocks: Array, avg_area: int) -> Array:
	var result = []
	# 0 -> small, 1 -> medium, 2 -> large, 3 -> very large
	for i in blocks:
		var area = i[1]
		if area <= avg_area * 1.2:
			result.append([i[0], area, 0])
		elif area <= avg_area * 1.8:
			result.append([i[0], area, 1])
		elif area <= avg_area * 2.4:
			result.append([i[0], area, 2])
		else:
			result.append([i[0], area, 3])

	return result

func get_building_height(pos: Vector2) -> float:
	var n = height_noise.get_noise_2d(pos.x, pos.y) # This gives value between [-1,1]
	var t = (n + 1.0) * 0.5                          # converting to [0,1]
	return lerp(min_building_height, max_building_height, t)

func get_building_base(height: float) -> Vector3:
	var base = 1 # minimum building width
	# height and width of city will depend on building's height
	var scale = sqrt(height)          # using sqrt of height as direct proportionality seems unreal
	var width = base * scale
	var length = base * scale * randf_range(0.8, 1.2)
	var d = sqrt( width**2 + length**2 ) / 2
	return Vector3(width, length, d)
	
func _ready():
	print("CityGenerator is running")
	
	total_block_area = 0.0
	polygon = city_polygons[randi_range(0,9)]
	points = poisson_disc_sampling_biased(min_radius, 20, angleSpreadDeg)
	triangles = delaunay_triangulation(points)
	edges = extract_edges_from_delaunay(points, triangles)
	mst_edges = minimumSpanningTree(edges, points.size())
	mst_edges = extract_mst_directional(mst_edges)
	secondary_edges = extract_secondary_directional(mst_edges, edges, points)
	all_edges = union_edges(points, secondary_edges, mst_edges, 0)
	#temp_blocks = extract_blocks(points, all_edges)
	#avg_area = total_block_area / len(temp_blocks)
	#city_blocks = classfiy_blocks_by_area(temp_blocks, avg_area)
	#for i in city_blocks:
		#print(i[0])
	height_noise.noise_type = 0
	height_noise.frequency = 0.002
	max_building_height = min_building_height * max_height_multiplier
	building_points = poisson_buildings(all_edges, height_noise)
	print(points.size())
	#print(len(city_blocks))
	
	#var areas = []
	#for row in city_blocks:
		#areas.append(row[1])
	
	#a = 0
	#b = 0
	#c = 0
	#d = 0
	#for area in areas:
		#if area <= avg_area * 1.2:
			#a += 1
		#elif area <= avg_area * 1.8:
			#b += 1
		#elif area <= avg_area * 2.4:
			#c += 1
		#else:
			#d += 1
	#print(a)
	#print(b)
	#print(c)
	#print(d)
	#print(avg_area)
	#print("total block area", total_block_area)
	#print("Printing block areas")
	for area in blocks_area:
		print(area)
	
	queue_redraw()

func _draw():
	if(show_roads):
		for e in secondary_edges:
			draw_line(points[e[0]], points[e[1]], Color.GRAY, 1.5)
		for e in mst_edges:
			draw_line(points[e[0]], points[e[1]], Color.WHITE, 3)
			
	for p in building_points:
		draw_circle(p[0], 2.5, Color.WHITE)

func _on_regenerate_button_pressed():
	
	total_block_area = 0.0
	points = poisson_disc_sampling_biased( min_radius, 30, angleSpreadDeg)
	triangles = delaunay_triangulation(points)
	edges = extract_edges_from_delaunay(points, triangles)
	mst_edges = minimumSpanningTree(edges, points.size())
	secondary_edges = extract_secondary_directional(mst_edges, edges, points)
	avg_area = total_block_area / blocks.size()
	queue_redraw()

var show_roads := true

func _on_toggle_button_pressed():
	show_roads = !show_roads
	queue_redraw()
