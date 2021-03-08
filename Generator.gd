#TODO: 
# - Store cells in chunks and unload meshes for chunks that the camera isn't in
# - Make get_index_kernel() work

extends Spatial

var RNG = RandomNumberGenerator.new()

export var cell_size = 1.0
export(PackedScene) var chunk_scene

var chunks = [] # [x][y][z]


func _input(event):
	if(Input.is_key_pressed(KEY_SPACE)):
		pass
	if(Input.is_key_pressed(KEY_C)):
		pass


func _physics_process(delta):
	#simulation_step(delta)
	pass


func _ready():
	var new_chunk = chunk_scene.instance()
	chunks.append(new_chunk)
	add_child(new_chunk)
