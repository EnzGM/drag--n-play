extends Control

const TELA_SELECAO_FASES = "res://Scenes/selecao_fases.tscn"


func _on_b_selecionar_fase_pressed():
	get_tree().change_scene_to_file(TELA_SELECAO_FASES)


func _on_b_sair_pressed():
	get_tree().quit()
