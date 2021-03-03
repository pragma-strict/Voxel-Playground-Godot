#TODO: 
# - Give the cells a single property and make it diffuse with neighbors
# - Store cells in chunks and unload meshes for chunks that the camera isn't in
# - Make get_index_kernel() work

extends Spatial

var RNG = RandomNumberGenerator.new()

export var cell_size = 1.0
export var chunk_width = 16
export var chunk_height = 4
export(PackedScene) var cell_scene

var stride_x
var stride_y
var stride_z

var cells = [] # [x][y][z]
var cell_nodes = [] # Node refs
var b_generated = false

func _ready():
	RNG.randomize()
	stride_x = chunk_width * chunk_height
	stride_y = chunk_height
	stride_z = 1

func _input(event):
	if(Input.is_key_pressed(KEY_SPACE) and !b_generated):
		generate_cells()
		generate_cell_nodes()
		b_generated = true
	if(Input.is_key_pressed(KEY_C)):
		randomize_cell_colors()

# Create and initialize all cells
func generate_cells():
	for i in range(chunk_width * chunk_width * chunk_height):
		cells.append(new_cell())

# Produce data for a single cell
func new_cell():
	var cell = {
		'type' : 0,
		'value' : randf()
	}
	return cell

# Add cells to the scene tree
func generate_cell_nodes():
	for i in range(len(cells)):
		var node = cell_scene.instance()
		var position = cell_index_to_coordinate(i) * cell_size
		node.translate(position)
		node.scale = Vector3(cell_size * 0.5, cell_size * 0.5, cell_size * 0.5)
		add_child(node)
		var cell_value = cells[i]['value']
		var cell_color = Color(cell_value, cell_value, cell_value)
		node.set_color(cell_color)
		cell_nodes.append(node)

# Randomize colors of existing cells
func randomize_cell_colors():
	for cell in cell_nodes:
		cell.set_color(Color(RNG.randf(), RNG.randf(), RNG.randf()))

# Return the indexes of cells surrounding a given index
func get_index_kernel(origin:int):
	var kernel = [[]]
	var top_row = []
	var middle_row = []
	var bottom_row = []
	var up = get_index_adjacent_to(origin, Vector3.UP)
	var down = get_index_adjacent_to(origin, Vector3.DOWN)
	var right = get_index_adjacent_to(origin, Vector3.RIGHT)
	var left = get_index_adjacent_to(origin, Vector3.LEFT)
	var forward = get_index_adjacent_to(origin, Vector3.FORWARD)
	var back = get_index_adjacent_to(origin, Vector3.BACK)
	top_row.append(get_index_adjacent_to(up, Vector3.LEFT))
	top_row.append(up)
	top_row.append(get_index_adjacent_to(up, Vector3.RIGHT))
	middle_row.append(left)
	middle_row.append(origin)
	middle_row.append(right)
	bottom_row.append(get_index_adjacent_to(down, Vector3.LEFT))
	bottom_row.append(down)
	bottom_row.append(0)
	return kernel

func get_index_adjacent_to(origin:int, direction:Vector3):
	var coordinate = cell_index_to_coordinate(origin)
	
	if(direction == Vector3.UP):
		if(coordinate.y < chunk_height -1):
			return origin + stride_z
		else:
			return cell_coordinate_to_index(Vector3(coordinate.x, 0, coordinate.z))
	
	if(direction == Vector3.DOWN):
		if(coordinate.y > 0):
			return origin - stride_z
		else:
			return cell_coordinate_to_index(Vector3(coordinate.x, chunk_height -1, coordinate.z))
	
	if(direction == Vector3.RIGHT):
		if(coordinate.x < chunk_width -1):
			return origin + stride_x
		else:
			return cell_coordinate_to_index(Vector3(0, coordinate.y, coordinate.z))
	
	if(direction == Vector3.LEFT):
		if(coordinate.x > 0):
			return origin - stride_x
		else:
			return cell_coordinate_to_index(Vector3(chunk_width -1, coordinate.y, coordinate.z))
	
	if(direction == Vector3.FORWARD):
		if(coordinate.z > 0):
			return origin - stride_z
		else:
			return cell_coordinate_to_index(Vector3(coordinate.x, coordinate.y, chunk_width -1))
	
	if(direction == Vector3.BACK):
		if(coordinate.z < chunk_width -1):
			return origin + stride_z
		else:
			return cell_coordinate_to_index(Vector3(coordinate.x, coordinate.y, 0))

# Return the Vector3 coordinate of the cell at a given index
func cell_index_to_coordinate(index:int):
	var coordinate = Vector3()
	coordinate.x = floor(index / (chunk_width * chunk_height))
	coordinate.y = int(floor(index / chunk_width)) % chunk_height
	coordinate.z = index % chunk_width
	return coordinate

# Return the index of the cell at a given coordinate
func cell_coordinate_to_index(coordinate:Vector3):
	var index = coordinate.x * stride_x
	index += coordinate.y * stride_y
	index += coordinate.z * stride_z
	return index
