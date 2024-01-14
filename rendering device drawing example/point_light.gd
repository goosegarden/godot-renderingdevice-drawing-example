extends Node

class_name point_light

var position = Vector3.ZERO
var color = Vector3(1.0,1.0,1.0)
var intensity = 1.0


func get_buffer() :
	var light_buffer = [
		position.x, -position.y, position.z, 
		color.x, color.y, color.z, 
		intensity
	]
	return PackedFloat32Array(light_buffer).to_byte_array()
