#TODO: see line 39

extends Spatial

var RNG = RandomNumberGenerator.new()

export var cell_size = 1
export var chunk_width = 16
export var chunk_height = 4

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
	if(Input.is_key_pressed(KEY_A)):
		print_tree_pretty()

func generate_cells():
	for i in range(chunk_width * chunk_width * chunk_height):
		var val = RNG.randi_range(0, 1)
		cells.append(val)

func generate_cell_nodes():
	for i in range(len(cells)):
		var node = MeshInstance.new()
		node.mesh = CubeMesh.new()
		var position = cell_index_to_coordinate(i) * cell_size
		node.translate(position)
		node.scale = Vector3(cell_size * 0.1, cell_size * 0.1, cell_size * 0.1)
		add_child(node)
		print("Created cube mesh at: ", position)

#TODO Make this function actually work. Or, generally, figure out how the cubes are actually being displayed.
func cell_index_to_coordinate(index:int):
	var coordinate = Vector3()
	coordinate.x = floor(index / stride_x)
	coordinate.y = floor((index % stride_x) / stride_y)
	coordinate.z = index % stride_y
	return coordinate

func cell_coordinate_to_index(coordinate:Vector3):
	var index = coordinate.x * stride_x
	index += coordinate.y * stride_y
	index += coordinate.z * stride_z
	return index