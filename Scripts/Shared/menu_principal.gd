extends Control

const TELA_SELECAO_FASES = "res://Scenes/Shared/selecao_fases.tscn"
const TELA_CONTROLES = "res://Scenes/Shared/controles.tscn"


func _on_b_selecionar_fase_pressed():
	get_tree().change_scene_to_file(TELA_SELECAO_FASES)


func _on_b_controles_pressed():
	get_tree().change_scene_to_file(TELA_CONTROLES)


func _on_b_sair_pressed():
	get_tree().quit()
