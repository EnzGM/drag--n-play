extends Node2D

enum Estado { JOGANDO, MORTO, VITORIA }

const MAX_COMANDOS = 5
const ESPACO_ENTRE_CAIXAS = 110.0

# Converte o "tipo_comando" da caixa pro comando que o Player entende.
const MAPA_COMANDOS = {
	"andar": "andar",
	"pular": "pular",
	"trás": "andar_tras",
}

var lista_montada = []
var comandos_no_trilho = []  # guarda as caixas (nós), na ordem em que aparecem
var posicao_inicial_player
var estado = Estado.JOGANDO

@onready var trilho: Control = $CanvasLayer/Trilho


func _ready():
	posicao_inicial_player = $Player.global_position
	atualizar_texto()


func _input(event):
	if estado != Estado.JOGANDO:
		return
	# event.is_echo() ignora os eventos de "auto-repeat" que o sistema manda
	# quando você segura a tecla pressionada. Sem isso, segurar "Executar"
	# chamava executar_comandos() várias vezes seguidas, reiniciando a
	# sequência do zero repetidamente — parecia que o personagem só andava
	# sem parar, porque o "pular" nunca tinha chance de terminar antes de
	# tudo reiniciar de novo.
	if event.is_action_pressed("Executar") and not event.is_echo():
		$Player.comandos = lista_montada
		$Player.executar_comandos()


# Chamado pelo caixa.gd toda vez que o jogador solta uma caixa.
func soltar_caixa(caixa):
	if estado != Estado.JOGANDO:
		return

	var centro = caixa.global_position + (caixa.size * caixa.scale) / 2.0
	var dentro_do_trilho = trilho.get_global_rect().has_point(centro)

	if dentro_do_trilho:
		if not comandos_no_trilho.has(caixa):
			if comandos_no_trilho.size() >= MAX_COMANDOS:
				# Limite de comandos atingido: a caixa não entra.
				caixa.queue_free()
				return
			comandos_no_trilho.append(caixa)
	elif comandos_no_trilho.has(caixa):
		# Foi arrastada pra fora do trilho: remove da sequência.
		comandos_no_trilho.erase(caixa)
		caixa.queue_free()

	reorganizar_trilho()


func remover_caixa(caixa):
	if estado != Estado.JOGANDO:
		return
	if comandos_no_trilho.has(caixa):
		comandos_no_trilho.erase(caixa)
	caixa.queue_free()
	reorganizar_trilho()


func reorganizar_trilho():
	# Ordena pela posição X atual, pra respeitar a ordem que o jogador montou.
	comandos_no_trilho.sort_custom(func(a, b): return a.global_position.x < b.global_position.x)

	for i in comandos_no_trilho.size():
		var caixa = comandos_no_trilho[i]
		caixa.global_position = trilho.global_position + Vector2(i * ESPACO_ENTRE_CAIXAS, 0)

	lista_montada.clear()
	for caixa in comandos_no_trilho:
		lista_montada.append(MAPA_COMANDOS.get(caixa.tipo_comando, caixa.tipo_comando))

	atualizar_texto()


func _on_b_limpar_pressed():
	if estado != Estado.JOGANDO:
		return
	$Player.interromper()
	for caixa in comandos_no_trilho:
		caixa.queue_free()
	comandos_no_trilho.clear()
	lista_montada.clear()
	atualizar_texto()


func atualizar_texto():
	var texto = " > ".join(lista_montada)
	if texto == "":
		texto = "(arraste as caixas até o trilho)"
	$CanvasLayer/ListaComandos.text = "%s\nComandos: %d/%d" % [texto, comandos_no_trilho.size(), MAX_COMANDOS]


func _on_objetivo_body_entered(body):
	if estado != Estado.JOGANDO:
		return
	estado = Estado.VITORIA
	$Player.interromper()
	get_tree().paused = true
	$CanvasLayer/TextoVitoria.visible = true
	$CanvasLayer/BReiniciar.visible = true


func _on_zona_de_morte_body_entered(body):
	if estado != Estado.JOGANDO:
		return
	estado = Estado.MORTO
	$Player.interromper()
	get_tree().paused = true
	$CanvasLayer/TextoDerrota.visible = true
	$CanvasLayer/BReiniciar.visible = true


func _on_b_reiniciar_pressed():
	get_tree().paused = false
	estado = Estado.JOGANDO
	$Player.global_position = posicao_inicial_player
	$Player.velocity = Vector2.ZERO
	$CanvasLayer/TextoVitoria.visible = false
	$CanvasLayer/TextoDerrota.visible = false
	$CanvasLayer/BReiniciar.visible = false
