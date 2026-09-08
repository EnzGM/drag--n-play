extends Node2D


func _input(event):
	if event.is_action_pressed("ui_select"):  # tecla espaço, por padrão
		$Player.executar_comandos()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
