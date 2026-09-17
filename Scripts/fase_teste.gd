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
var ja_executou = false  # trava o play depois do primeiro uso, até reiniciar
var menu_aberto = false

# Caminho da cena da próxima fase. Deixe em branco (como aqui, na fase_teste)
# se não tiver "próxima". Em cada cena herdada (fase_1, fase_2...), selecione
# o nó raiz e preenche esse campo no Inspector — não precisa mexer em código.
@export_file("*.tscn") var proxima_fase: String = ""

@onready var trilho: Control = $CanvasLayer/Trilho


func _ready():
	posicao_inicial_player = $Player.global_position
	# Garante que tudo comece visível ao rodar, mesmo que você tenha
	# escondido o CanvasLayer inteiro ou só a paleta/trilho no editor
	# (ícone de olho) pra facilitar de mexer no layout da fase sem UI
	# no meio.
	$CanvasLayer.visible = true
	mostrar_caixas()
	atualizar_texto()


func _input(event):
	if not (event is InputEventKey) or not event.pressed or event.is_echo():
		return

	# ESC abre/fecha o menu de pausa a qualquer momento (menos nas telas
	# de vitória/derrota, que já têm a navegação delas).
	if event.keycode == KEY_ESCAPE:
		alternar_menu_pausa()
		return

	# R reinicia a fase a qualquer momento, até durante a tela de
	# vitória/derrota (o process_mode do nó cuida disso).
	if event.keycode == KEY_R:
		reiniciar_fase()
		return

	if menu_aberto or estado != Estado.JOGANDO:
		return

	# Enter (ou o botão "Executar" configurado no Input Map) dá play.
	if event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER or event.is_action_pressed("Executar"):
		iniciar_execucao()


func alternar_menu_pausa():
	if estado != Estado.JOGANDO:
		return
	menu_aberto = not menu_aberto
	get_tree().paused = menu_aberto
	$CanvasLayer/MenuPausa.visible = menu_aberto


func _on_b_menu_pressed():
	alternar_menu_pausa()


func _on_b_continuar_pressed():
	alternar_menu_pausa()


func _on_b_menu_reiniciar_pressed():
	reiniciar_fase()


func _on_b_menu_selecionar_fase_pressed():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Scenes/selecao_fases.tscn")


func _on_b_menu_principal_pressed():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Scenes/menu_principal.tscn")


func iniciar_execucao():
	if estado != Estado.JOGANDO or $Player.executando or ja_executou or lista_montada.is_empty():
		return
	ja_executou = true
	$CanvasLayer/BPlay.disabled = true
	esconder_caixas()
	$Player.comandos = lista_montada
	await $Player.executar_comandos()

	# A fila acabou. Se ninguém venceu nem morreu nesse meio tempo, não tem
	# mais nada programado pra fazer — mostra o botão de reiniciar.
	if estado == Estado.JOGANDO:
		$CanvasLayer/BReiniciar.visible = true


func _on_b_play_pressed():
	iniciar_execucao()


func esconder_caixas():
	$CanvasLayer/Caixas.visible = false
	for caixa in comandos_no_trilho:
		caixa.visible = false


func mostrar_caixas():
	$CanvasLayer/Caixas.visible = true
	for caixa in comandos_no_trilho:
		caixa.visible = true


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
	else:
		# Solta fora do trilho: some sempre, esteja ela já na fila ou seja
		# uma cópia nova que nunca chegou a entrar.
		if comandos_no_trilho.has(caixa):
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
	if body != $Player:
		return
	if estado != Estado.JOGANDO:
		return
	estado = Estado.VITORIA
	$Player.interromper()
	get_tree().paused = true
	$CanvasLayer/TextoVitoria.visible = true
	$CanvasLayer/BReiniciar.visible = true
	$CanvasLayer/BProximaFase.visible = not proxima_fase.is_empty()


func _on_b_proxima_fase_pressed():
	if proxima_fase.is_empty():
		return
	get_tree().paused = false
	get_tree().change_scene_to_file(proxima_fase)


func _on_zona_de_morte_body_entered(body):
	if body != $Player:
		return
	if estado != Estado.JOGANDO:
		return
	estado = Estado.MORTO
	$Player.interromper()
	get_tree().paused = true
	$CanvasLayer/TextoDerrota.visible = true
	$CanvasLayer/BReiniciar.visible = true


func _on_b_reiniciar_pressed():
	reiniciar_fase()


func reiniciar_fase():
	$Player.interromper()
	$Player.executando = false
	ja_executou = false
	$CanvasLayer/BPlay.disabled = false

	for caixa in comandos_no_trilho:
		caixa.queue_free()
	comandos_no_trilho.clear()
	lista_montada.clear()
	atualizar_texto()

	get_tree().paused = false
	estado = Estado.JOGANDO
	menu_aberto = false
	$CanvasLayer/MenuPausa.visible = false
	$Player.global_position = posicao_inicial_player
	$Player.velocity = Vector2.ZERO
	$CanvasLayer/TextoVitoria.visible = false
	$CanvasLayer/TextoDerrota.visible = false
	$CanvasLayer/BReiniciar.visible = false
	$CanvasLayer/BProximaFase.visible = false
	mostrar_caixas()
