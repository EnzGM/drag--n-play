extends Node2D

var lista_montada = []
var posicao_inicial_player


func _ready():
	posicao_inicial_player = $Player.global_position


func _input(event):
	if event.is_action_pressed("Executar"):
		$Player.comandos = lista_montada
		$Player.executar_comandos()


func _on_b_andar_pressed():
	lista_montada.append("andar")
	atualizar_texto()

func _on_b_atras_pressed():
	lista_montada.append("andar_tras")
	atualizar_texto()

func _on_b_pular_pressed():
	lista_montada.append("pular")
	atualizar_texto()


func _on_b_limpar_pressed():
	$Player.interromper()
	lista_montada.clear()
	atualizar_texto()


func atualizar_texto():
	$CanvasLayer/ListaComandos.text = " > ".join(lista_montada)


func _on_objetivo_body_entered(body):
	$"CanvasLayer/TextoVitoria".visible = true
	$"CanvasLayer/BReiniciar".visible = true


func _on_zona_de_morte_body_entered(body):
	$Player.interromper()
	$Player.global_position = posicao_inicial_player
	$Player.velocity = Vector2.ZERO
	lista_montada.clear()
	atualizar_texto()
	$CanvasLayer/TextoVitoria.visible = false


func _on_b_reiniciar_pressed():
	$Player.global_position = posicao_inicial_player
	$Player.velocity = Vector2.ZERO
	lista_montada.clear()
	atualizar_texto()
	$"CanvasLayer/TextoVitoria".visible = false
	$"CanvasLayer/BReiniciar".visible = false
