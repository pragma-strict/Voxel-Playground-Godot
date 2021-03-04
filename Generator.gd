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
export var processes_per_frame = 16

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
	generate_cells()
	b_generated = true


func _input(event):
	if(Input.is_key_pressed(KEY_SPACE) and !b_generated):
		pass
	if(Input.is_key_pressed(KEY_C)):
		pass


func _physics_process(delta):
	simulation_step(delta)


func simulation_step(delta):
	for i in range(processes_per_frame):
		var index = RNG.randi_range(0, len(cells) -1)
		kernel_average_single(index)
		kernel_conway_single(index)


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
	var is_alive = false
	if (randf() > 0.9):
		is_alive = true
	var cell = {
		'type' : 0,
		'alive': is_alive,
		'value' : value,
		'node' : generate_cell_node(index, color, is_alive)
	}
	return cell


# Create and return a cell node. Also adds it to the scene tree.
func generate_cell_node(index:int, color:Color, is_alive:bool):
	var node = cell_scene.instance()
	var position = cell_index_to_coordinate(index) * cell_size
	node.translate(position)
	node.scale = Vector3(cell_size * 0.5, cell_size * 0.5, cell_size * 0.5)
	add_child(node)
	node.set_color(color)
	node.set_alive(is_alive)
	return node


# Set cell colors according to values
func update_cell_colors():
	for cell in cells:
		cell['node'].set_color(Color(cell['value'], cell['value'], cell['value']))


func update_cell_color(index:int):
	var value = cells[index]['value']
	cells[index]['node'].set_color(Color(value, value, value))


func update_cell(index:int):
	#var value = cells[index]['value']
	#cells[index]['node'].set_color(Color(value, value, value))
	cells[index]['node'].set_alive(cells[index]['alive'])


# Average the values in each cell with neighboring cells
func kernel_average_all():
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


func kernel_average_single(index:int):
	var sum = 0
	var cells_in_kernel = 0
	for k in range(len(index_offset_kernel)):
		var offset_index = index + index_offset_kernel[k]
		if offset_index >= 0 and offset_index < len(cells):
			cells_in_kernel += 1
			sum += cells[offset_index]['value']
	var value = (cells[index]['value'] + sum / cells_in_kernel) /2
	cells[index]['value'] = value
	update_cell_color(index)


# Perform a conway-style kernel operation
func kernel_conway_single(index:int):
	var living_neighbors = 0
	for k in range(len(index_offset_kernel)):
		var offset_index = index + index_offset_kernel[k]
		if offset_index >= 0 and offset_index < len(cells):
			if cells[offset_index]['alive']:
				living_neighbors += 1
	if (living_neighbors >= 8) or (living_neighbors <= 3):
		cells[index]['alive'] = false
	else:
		cells[index]['alive'] = true
	update_cell(index)


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
