extends Node2D

var lista_montada = []

func _input(event):
	if event.is_action_pressed("Executar"):
		$Player.comandos = lista_montada
		$Player.executar_comandos()


func _on_b_andar_pressed():
	lista_montada.append("andar")
	atualizar_texto()


func _on_b_pular_pressed():
	lista_montada.append("pular")
	atualizar_texto()


func _on_b_limpar_pressed():
	lista_montada.clear()
	atualizar_texto()


func atualizar_texto():
	$CanvasLayer/ListaComandos.text = " > ".join(lista_montada)
