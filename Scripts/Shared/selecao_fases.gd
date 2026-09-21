extends Control

const FASE_TUTORIAL = "res://Scenes/Plataformer/fase_tutorial.tscn"
const FASE_1 = "res://Scenes/Plataformer/fase_1.tscn"
const FASE_2 = "res://Scenes/TopDown/fase_2.tscn"
const MENU_PRINCIPAL = "res://Scenes/Shared/menu_principal.tscn"


func _on_b_tutorial_pressed():
	get_tree().change_scene_to_file(FASE_TUTORIAL)


func _on_b_fase_1_pressed():
	get_tree().change_scene_to_file(FASE_1)


func _on_b_fase_2_pressed():
	get_tree().change_scene_to_file(FASE_2)


func _on_b_voltar_pressed():
	get_tree().change_scene_to_file(MENU_PRINCIPAL)
