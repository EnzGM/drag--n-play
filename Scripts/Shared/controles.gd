extends Control

const MENU_PRINCIPAL = "res://Scenes/Shared/menu_principal.tscn"


func _on_b_voltar_pressed():
	get_tree().change_scene_to_file(MENU_PRINCIPAL)
