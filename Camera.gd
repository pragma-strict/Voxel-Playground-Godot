extends Camera

export var move_speed = 0.2

func _input(event):
	if(Input.is_key_pressed(KEY_A)):
		translate(Vector3(-move_speed, 0, 0))
	elif(Input.is_key_pressed(KEY_D)):
		translate(Vector3(move_speed, 0, 0))
	if(Input.is_key_pressed(KEY_Q)):
		translate(Vector3(0, -move_speed, 0))
	elif(Input.is_key_pressed(KEY_E)):
		translate(Vector3(0, move_speed, 0))
	if(Input.is_key_pressed(KEY_W)):
		translate(Vector3(0, 0, -move_speed))
	elif(Input.is_key_pressed(KEY_S)):
		translate(Vector3(0, 0, move_speed))