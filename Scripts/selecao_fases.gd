extends Control

const FASE_TESTE = "res://Scenes/fase_teste.tscn"
const FASE_1 = "res://Scenes/fase_1.tscn"
const MENU_PRINCIPAL = "res://Scenes/menu_principal.tscn"


func _on_b_fase_teste_pressed():
	get_tree().change_scene_to_file(FASE_TESTE)


func _on_b_fase_1_pressed():
	get_tree().change_scene_to_file(FASE_1)


func _on_b_voltar_pressed():
	get_tree().change_scene_to_file(MENU_PRINCIPAL)
