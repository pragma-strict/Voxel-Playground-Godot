extends MeshInstance

var color

func _ready():
	mesh = CubeMesh.new()

func set_color(new_col):
	color = new_col
	var mat = SpatialMaterial.new()
	mat.albedo_color = new_col
	mesh.surface_set_material(0, mat)
