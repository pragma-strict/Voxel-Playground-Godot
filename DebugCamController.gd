extends Camera

export(float, 0.1, 1.0) var mouse_sensitivity = 0.1
export(float, 1.0, 100.0) var movement_speed = 1.0
export(Dictionary) var input_mappings = {
	"forward" : "move_forward",
	"backward" : "move_backward",
	"left" : "move_left",
	"right" : "move_right",
	"up" : "move_up",
	"down" : "move_down"
	}

var is_mouse_captured = false

func _ready():
	pass
	#Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
func _physics_process(delta):
	if(Input.is_action_pressed(input_mappings["up"])):
		global_translate(Vector3(0, movement_speed * delta, 0))
	
	if(Input.is_action_pressed(input_mappings["down"])):
		global_translate(Vector3(0, -movement_speed * delta, 0))
	
	if(Input.is_action_pressed(input_mappings["right"])):
		translate(Vector3(movement_speed * delta, 0, 0))
	
	if(Input.is_action_pressed(input_mappings["left"])):
		translate(Vector3(-movement_speed * delta, 0, 0))
	
	if(Input.is_action_pressed(input_mappings["forward"])):
		translate(Vector3(0, 0, -movement_speed * delta))
	
	if(Input.is_action_pressed(input_mappings["backward"])):
		translate(Vector3(0, 0, movement_speed * delta))
	
func _input(event):
	if (event is InputEventMouseMotion):
		var mouse_motion = event.relative
		global_rotate(Vector3(0, 1, 0), -deg2rad(mouse_motion.x) * mouse_sensitivity)
		rotate_object_local(Vector3(1, 0, 0), -deg2rad(mouse_motion.y) * mouse_sensitivity)
	
	if (event is InputEventMouseButton):
		is_mouse_captured = true
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	if (Input.is_action_pressed("ui_fullscreen")):
		OS.window_fullscreen = !OS.window_fullscreen
	
	if (Input.is_key_pressed(KEY_ESCAPE)):
		get_tree().quit()

