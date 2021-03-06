extends Node

class_name Chunk

var RNG = RandomNumberGenerator.new()

var chunk_size = 8
var processes_per_frame = 16

var stride_x
var stride_y
var stride_z

var index_offset_kernel

var cells = [] # [x][y][z]
var mesh = ImmediateGeometry.new()


func _ready():
	update_mesh()
	#RNG.randomize()


func update_mesh():
	mesh.clear()
	
	mesh.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# Prepare attributes for add_vertex.
	mesh.set_normal( Vector3(0, 0, 1))
	mesh.set_uv(Vector2(0, 0))
	
	# Call last for each vertex, adds the above attributes.
	mesh.add_vertex(Vector3(-1, -1, 0))

	mesh.set_normal(Vector3(0, 0, 1))
	mesh.set_uv(Vector2(0, 1))
	mesh.add_vertex(Vector3(-1, 1, 0))

	mesh.set_normal(Vector3(0, 0, 1))
	mesh.set_uv(Vector2(1, 1))
	mesh.add_vertex(Vector3(1, 1, 0))

	# End drawing.
	mesh.end()
	add_child(mesh)


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
	for i in range(chunk_size * chunk_size * chunk_size):
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
		'value' : value
	}
	return cell


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
	#update_cell_colors()


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
	#update_cell_color(index)


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
	#update_cell(index)


func get_index_adjacent_to(origin:int, direction:Vector3):
	var coordinate = cell_index_to_coordinate(origin)
	
	if(direction == Vector3.UP):
		if(coordinate.y < chunk_size -1):
			return origin + stride_z
		else:
			return cell_coordinate_to_index(Vector3(coordinate.x, 0, coordinate.z))
	
	if(direction == Vector3.DOWN):
		if(coordinate.y > 0):
			return origin - stride_z
		else:
			return cell_coordinate_to_index(Vector3(coordinate.x, chunk_size -1, coordinate.z))
	
	if(direction == Vector3.RIGHT):
		if(coordinate.x < chunk_size -1):
			return origin + stride_x
		else:
			return cell_coordinate_to_index(Vector3(0, coordinate.y, coordinate.z))
	
	if(direction == Vector3.LEFT):
		if(coordinate.x > 0):
			return origin - stride_x
		else:
			return cell_coordinate_to_index(Vector3(chunk_size -1, coordinate.y, coordinate.z))
	
	if(direction == Vector3.FORWARD):
		if(coordinate.z > 0):
			return origin - stride_z
		else:
			return cell_coordinate_to_index(Vector3(coordinate.x, coordinate.y, chunk_size -1))
	
	if(direction == Vector3.BACK):
		if(coordinate.z < chunk_size -1):
			return origin + stride_z
		else:
			return cell_coordinate_to_index(Vector3(coordinate.x, coordinate.y, 0))


# Return the Vector3 coordinate of the cell at a given index
func cell_index_to_coordinate(index:int):
	var coordinate = Vector3()
	coordinate.x = floor(index / (chunk_size * chunk_size))
	coordinate.y = int(floor(index / chunk_size)) % chunk_size
	coordinate.z = index % chunk_size
	return coordinate


# Return the index of the cell at a given coordinate
func cell_coordinate_to_index(coordinate:Vector3):
	var index = coordinate.x * stride_x
	index += coordinate.y * stride_y
	index += coordinate.z * stride_z
	return index
