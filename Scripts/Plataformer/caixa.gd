extends Control

var arrastando = false
var offset_mouse = Vector2.ZERO
@export var tipo_comando = "andar"
@export var e_modelo = false


func _ready():
	$ColorRect/Label.text = tipo_comando


func _gui_input(event):
	# Só cuidamos do CLIQUE aqui. O "soltar o mouse" é tratado no _process,
	# porque quando a caixa é uma cópia recém-criada a partir de um modelo,
	# quem recebeu o clique original foi o modelo (não a cópia), então o
	# evento de "soltar" nunca chegaria até a cópia por aqui.
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if e_modelo:
				var copia = duplicate()
				get_tree().current_scene.get_node("CanvasLayer").add_child(copia)
				copia.e_modelo = false
				copia.global_position = global_position
				copia.arrastando = true
				copia.offset_mouse = get_global_mouse_position() - copia.global_position
			else:
				arrastando = true
				offset_mouse = get_global_mouse_position() - global_position
		elif event.button_index == MOUSE_BUTTON_RIGHT and not e_modelo:
			# Clique direito remove essa caixa da fila na hora, sem
			# precisar arrastar ela pra fora do trilho.
			arrastando = false
			if get_tree().current_scene.has_method("remover_caixa"):
				get_tree().current_scene.remover_caixa(self)


func _process(_delta):
	if not arrastando:
		return

	global_position = get_global_mouse_position() - offset_mouse

	# Checa se o botão do mouse ainda está pressionado (polling), em vez de
	# esperar um evento de "release" que pode nunca chegar até essa caixa.
	if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		arrastando = false
		if get_tree().current_scene.has_method("soltar_caixa"):
			get_tree().current_scene.soltar_caixa(self)
