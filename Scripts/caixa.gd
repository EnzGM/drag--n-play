extends Control

var arrastando = false
var offset_mouse = Vector2.ZERO
@export var tipo_comando = "andar"


func _ready():
	$ColorRect/Label.text = tipo_comando


func _gui_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			arrastando = true
			offset_mouse = get_global_mouse_position() - global_position
		else:
			arrastando = false


func _process(_delta):
	if arrastando:
		global_position = get_global_mouse_position() - offset_mouse
