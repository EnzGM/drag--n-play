extends Control

# Ajuste esse caminho pra apontar pra primeira fase do seu jogo.
const PRIMEIRA_FASE = "res://Scenes/fase_teste.tscn"


func _on_b_jogar_pressed():
	get_tree().change_scene_to_file(PRIMEIRA_FASE)


func _on_b_sair_pressed():
	get_tree().quit()
