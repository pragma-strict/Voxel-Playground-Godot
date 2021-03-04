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

var index_offset_kernel

var cells = [] # [x][y][z]
var cell_nodes = [] # Node refs
var b_generated = false

func _ready():
	RNG.randomize()
	stride_x = chunk_width * chunk_height
	stride_y = chunk_height
	stride_z = 1
	init_offset_kernel()

func _input(event):
	if(Input.is_key_pressed(KEY_SPACE) and !b_generated):
		generate_cells()
		b_generated = true
	if(Input.is_key_pressed(KEY_C)):
		kernel_diffuse()

# Create the kernel of index offsets
func init_offset_kernel():
	index_offset_kernel = [
		cell_coordinate_to_index(Vector3(-1, -1, -1)),
		cell_coordinate_to_index(Vector3(-1, -1, 0)),
		cell_coordinate_to_index(Vector3(-1, -1, 1)),
		cell_coordinate_to_index(Vector3(0, -1, -1)),
		cell_coordinate_to_index(Vector3(0, -1, 0)),
		cell_coordinate_to_index(Vector3(0, -1, 1)),
		cell_coordinate_to_index(Vector3(1, -1, -1)),
		cell_coordinate_to_index(Vector3(1, -1, 0)),
		cell_coordinate_to_index(Vector3(1, -1, 1)),
		cell_coordinate_to_index(Vector3(-1, 0, -1)),
		cell_coordinate_to_index(Vector3(-1, 0, 0)),
		cell_coordinate_to_index(Vector3(-1, 0, 1)),
		cell_coordinate_to_index(Vector3(0, 0, -1)),
		cell_coordinate_to_index(Vector3(0, 0, 0)),
		cell_coordinate_to_index(Vector3(0, 0, 1)),
		cell_coordinate_to_index(Vector3(1, 0, -1)),
		cell_coordinate_to_index(Vector3(1, 0, 0)),
		cell_coordinate_to_index(Vector3(1, 0, 1)),
		cell_coordinate_to_index(Vector3(-1, 1, -1)),
		cell_coordinate_to_index(Vector3(-1, 1, 0)),
		cell_coordinate_to_index(Vector3(-1, 1, 1)),
		cell_coordinate_to_index(Vector3(0, 1, -1)),
		cell_coordinate_to_index(Vector3(0, 1, 0)),
		cell_coordinate_to_index(Vector3(0, 1, 1)),
		cell_coordinate_to_index(Vector3(1, 1, -1)),
		cell_coordinate_to_index(Vector3(1, 1, 0)),
		cell_coordinate_to_index(Vector3(1, 1, 1))
	]

# Create the kernel of index offsets as a nested array
func init_offset_kernel_nested():
	index_offset_kernel = [
		[
			[
				cell_coordinate_to_index(Vector3(-1, -1, -1)),
				cell_coordinate_to_index(Vector3(-1, -1, 0)),
				cell_coordinate_to_index(Vector3(-1, -1, 1))
			],
			[
				cell_coordinate_to_index(Vector3(0, -1, -1)),
				cell_coordinate_to_index(Vector3(0, -1, 0)),
				cell_coordinate_to_index(Vector3(0, -1, 1))
			],
			[
				cell_coordinate_to_index(Vector3(1, -1, -1)),
				cell_coordinate_to_index(Vector3(1, -1, 0)),
				cell_coordinate_to_index(Vector3(1, -1, 1))
			]
		],
		[
			[
				cell_coordinate_to_index(Vector3(-1, 0, -1)),
				cell_coordinate_to_index(Vector3(-1, 0, 0)),
				cell_coordinate_to_index(Vector3(-1, 0, 1))
			],
			[
				cell_coordinate_to_index(Vector3(0, 0, -1)),
				cell_coordinate_to_index(Vector3(0, 0, 0)),
				cell_coordinate_to_index(Vector3(0, 0, 1))
			],
			[
				cell_coordinate_to_index(Vector3(1, 0, -1)),
				cell_coordinate_to_index(Vector3(1, 0, 0)),
				cell_coordinate_to_index(Vector3(1, 0, 1))
			]
		],
		[
			[
				cell_coordinate_to_index(Vector3(-1, 1, -1)),
				cell_coordinate_to_index(Vector3(-1, 1, 0)),
				cell_coordinate_to_index(Vector3(-1, 1, 1))
			],
			[
				cell_coordinate_to_index(Vector3(0, 1, -1)),
				cell_coordinate_to_index(Vector3(0, 1, 0)),
				cell_coordinate_to_index(Vector3(0, 1, 1))
			],
			[
				cell_coordinate_to_index(Vector3(1, 1, -1)),
				cell_coordinate_to_index(Vector3(1, 1, 0)),
				cell_coordinate_to_index(Vector3(1, 1, 1))
			]
		]
	]

# Create and initialize all cells
func generate_cells():
	for i in range(chunk_width * chunk_width * chunk_height):
		cells.append(new_cell(i))

# Produce data for a single cell
func new_cell(index:int):
	var value = randf()
	var color = Color(value, value, value)
	var cell = {
		'type' : 0,
		'value' : value,
		'node' : generate_cell_node(index, color)
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

# Create and return a cell node. Also adds it to the scene tree.
func generate_cell_node(index:int, color:Color):
	var node = cell_scene.instance()
	var position = cell_index_to_coordinate(index) * cell_size
	node.translate(position)
	node.scale = Vector3(cell_size * 0.5, cell_size * 0.5, cell_size * 0.5)
	add_child(node)
	node.set_color(color)
	return node

# Randomize colors of existing cells
func randomize_cell_colors():
	for cell in cells:
		cell['node'].set_color(Color(RNG.randf(), RNG.randf(), RNG.randf()))

# Set cell colors according to values
func update_cell_colors():
	for cell in cells:
		cell['node'].set_color(Color(cell['value'], cell['value'], cell['value']))

# Average the values in each cell with neighboring cells
func kernel_diffuse():
	for i in range(len(cells)):
		var sum = 0
		var cells_in_kernel = 0
		for k in range(len(index_offset_kernel)):
			var offset_index = i + index_offset_kernel[k]
			if offset_index >= 0 and offset_index < len(cells):
				cells_in_kernel += 1
				sum += cells[offset_index]['value']
		cells[i]['value'] = sum / cells_in_kernel
	update_cell_colors()

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
