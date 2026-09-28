extends Control

const MENU_PRINCIPAL = "res://Scenes/Shared/menu_principal.tscn"


func _on_b_voltar_pressed():
	TransicaoCenas.trocar_para(MENU_PRINCIPAL)
