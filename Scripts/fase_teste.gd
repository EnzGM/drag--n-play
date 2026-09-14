extends Node2D

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

@onready var trilho: Control = $CanvasLayer/Trilho


func _ready():
	posicao_inicial_player = $Player.global_position
	atualizar_texto()


func _input(event):
	if event.is_action_pressed("Executar"):
		$Player.comandos = lista_montada
		$Player.executar_comandos()


# Chamado pelo caixa.gd toda vez que o jogador solta uma caixa.
func soltar_caixa(caixa):
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


# Os botões antigos ficam como stub (não fazem mais nada) pra não quebrar
# as conexões de sinal que já existem na cena. Dá pra apagar os botões
# e essas funções mais pra frente, quando não precisar mais deles.
func _on_b_andar_pressed():
	pass

func _on_b_atras_pressed():
	pass

func _on_b_pular_pressed():
	pass


func _on_b_limpar_pressed():
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
	$"CanvasLayer/TextoVitoria".visible = true
	$"CanvasLayer/BReiniciar".visible = true


func _on_zona_de_morte_body_entered(body):
	$Player.interromper()
	$Player.global_position = posicao_inicial_player
	$Player.velocity = Vector2.ZERO
	$CanvasLayer/TextoVitoria.visible = false


func _on_b_reiniciar_pressed():
	$Player.global_position = posicao_inicial_player
	$Player.velocity = Vector2.ZERO
	$"CanvasLayer/TextoVitoria".visible = false
	$"CanvasLayer/BReiniciar".visible = false
