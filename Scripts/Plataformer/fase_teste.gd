extends Node2D

enum Estado { JOGANDO, MORTO, VITORIA }

# Folga (em pixels) entre uma caixa e outra no trilho. O espaço total é o
# tamanho real da caixa + essa folga, então dá pra apertar ou afrouxar aqui.
const FOLGA_ENTRE_CAIXAS = 8.0   # lado a lado (horizontal)
const FOLGA_ENTRE_LINHAS = 6.0   # entre linhas (vertical)

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

# Texto do tutorial mostrado ao entrar na fase (pausado, com botão "Entendi").
# Deixe em branco (como aqui, na fase_teste) se a fase não tiver tutorial.
@export_multiline var texto_tutorial: String = ""

# Imagem opcional mostrada junto do texto do tutorial (ex: ilustrando que a
# ordem de execução segue a ordem das caixas no trilho). Deixe em branco se
# não quiser imagem nenhuma.
@export var imagem_tutorial: Texture2D = null

# Quantas caixas cabem no trilho. 5 é o padrão; a fase_tutorial usa um
# número bem maior pra funcionar como "ilimitado" na prática.
@export var max_comandos: int = 5

# Se false, a ZonaDeMorte não mata — usado na fase_tutorial, onde não tem
# como perder.
@export var pode_morrer: bool = true

# Se true, dá pra apertar Play quantas vezes quiser sem precisar reiniciar:
# ao acabar a sequência, o personagem volta sozinho pro início e libera o
# Play de novo na hora. Usado na fase_tutorial, pra você poder testar à
# vontade.
@export var permitir_repetir: bool = false

# Som ambiente em loop pra essa fase (opcional). Deixe em branco (como
# aqui, na fase_teste) se a fase não tiver som ambiente próprio.
@export var som_ambiente: AudioStream = null

@onready var trilho: Control = $CanvasLayer/Trilho


func _ready():
	posicao_inicial_player = $Player.global_position
	$Player.comando_avancou.connect(_on_comando_avancou)
	# Garante que tudo comece visível ao rodar, mesmo que você tenha
	# escondido o CanvasLayer inteiro ou só a paleta/trilho no editor
	# (ícone de olho) pra facilitar de mexer no layout da fase sem UI
	# no meio.
	$CanvasLayer.visible = true
	mostrar_caixas()
	atualizar_texto()

	if som_ambiente:
		$SomAmbiente.stream = som_ambiente
		$SomAmbiente.finished.connect($SomAmbiente.play)  # loop manual
		$SomAmbiente.play()

	if not texto_tutorial.is_empty():
		$CanvasLayer/PainelTutorial/Conteudo/Rolagem/Label.text = texto_tutorial
		$CanvasLayer/PainelTutorial/Conteudo/Imagem.texture = imagem_tutorial
		$CanvasLayer/PainelTutorial/Conteudo/Imagem.visible = imagem_tutorial != null
		$CanvasLayer/PainelTutorial.visible = true
		$SomAparecerPainel.play()
		get_tree().paused = true
	else:
		$CanvasLayer/PainelTutorial.visible = false


func _on_b_entendi_pressed():
	$CanvasLayer/PainelTutorial.visible = false
	if estado == Estado.JOGANDO:
		get_tree().paused = false


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
	if menu_aberto:
		$SomAparecerPainel.play()
	$CanvasLayer/MenuPausa.visible = menu_aberto
	$CanvasLayer/PainelControles.visible = false


func _on_b_menu_pressed():
	alternar_menu_pausa()


func _on_b_continuar_pressed():
	alternar_menu_pausa()


func _on_b_menu_reiniciar_pressed():
	reiniciar_fase()


func _on_b_menu_controles_pressed():
	$CanvasLayer/MenuPausa.visible = false
	$CanvasLayer/PainelControles.visible = true
	$SomAparecerPainel.play()


func _on_b_controles_voltar_pressed():
	$CanvasLayer/PainelControles.visible = false
	$CanvasLayer/MenuPausa.visible = true


func _on_b_menu_selecionar_fase_pressed():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Scenes/Shared/selecao_fases.tscn")


func _on_b_menu_principal_pressed():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Scenes/Shared/menu_principal.tscn")


func iniciar_execucao():
	if estado != Estado.JOGANDO or $Player.executando or lista_montada.is_empty():
		return
	if ja_executou and not permitir_repetir:
		return

	ja_executou = true
	if not permitir_repetir:
		$CanvasLayer/BPlay.disabled = true
	esconder_caixas()
	$Player.comandos = lista_montada
	await $Player.executar_comandos()

	if permitir_repetir:
		# Modo tutorial: sem risco de morrer e sem limite de tentativas —
		# volta o personagem pro início sozinho e libera pra tentar de
		# novo na hora, sem precisar apertar Reiniciar.
		$Player.global_position = posicao_inicial_player
		$Player.velocity = Vector2.ZERO
		ja_executou = false
		mostrar_caixas()
		return

	# A fila acabou. Se ninguém venceu nem morreu nesse meio tempo, não tem
	# mais nada programado pra fazer — mostra o botão de reiniciar.
	if estado == Estado.JOGANDO:
		$CanvasLayer/BReiniciar.visible = true


func _on_b_play_pressed():
	iniciar_execucao()


func esconder_caixas():
	# Só esconde a paleta (de onde você arrasta novas caixas) — as que já
	# estão no trilho ficam visíveis durante a execução, pra dar pra ver
	# a setinha indicando qual comando tá rodando.
	$CanvasLayer/Caixas.visible = false


func mostrar_caixas():
	$CanvasLayer/Caixas.visible = true


# Chamado pelo caixa.gd toda vez que o jogador solta uma caixa.
func soltar_caixa(caixa):
	if estado != Estado.JOGANDO:
		return

	var centro = caixa.global_position + (caixa.size * caixa.scale) / 2.0
	var dentro_do_trilho = trilho.get_global_rect().has_point(centro)

	if dentro_do_trilho:
		if not comandos_no_trilho.has(caixa):
			if comandos_no_trilho.size() >= max_comandos:
				# Limite de comandos atingido: a caixa não entra.
				$SomCancelar.play()
				caixa.queue_free()
				return
			$SomCaixaEncaixada.play()
			comandos_no_trilho.append(caixa)
	else:
		# Solta fora do trilho: some sempre, esteja ela já na fila ou seja
		# uma cópia nova que nunca chegou a entrar.
		if comandos_no_trilho.has(caixa):
			comandos_no_trilho.erase(caixa)
		$SomCaixaRemovida.play()
		caixa.queue_free()

	reorganizar_trilho()


func remover_caixa(caixa):
	if estado != Estado.JOGANDO:
		return
	if comandos_no_trilho.has(caixa):
		comandos_no_trilho.erase(caixa)
	$SomCaixaRemovida.play()
	caixa.queue_free()
	reorganizar_trilho()


func _espaco_entre_caixas() -> Vector2:
	# Espaço de uma célula do trilho = tamanho real da caixa (já com a escala)
	# + a folga. Assim as caixas ficam sempre juntinhas, sem depender de um
	# número fixo que não bate com o tamanho delas.
	if comandos_no_trilho.is_empty():
		return Vector2(70.0, 35.0)
	var tamanho = comandos_no_trilho[0].size * comandos_no_trilho[0].scale
	return Vector2(tamanho.x + FOLGA_ENTRE_CAIXAS, tamanho.y + FOLGA_ENTRE_LINHAS)


func reorganizar_trilho():
	# Ao entrar no trilho, cada caixa fica menor para caber uma sequência
	# completa sem ultrapassar o espaço disponível.
	var escala_trilho = 0.55
	for caixa in comandos_no_trilho:
		caixa.scale = Vector2(escala_trilho, escala_trilho)

	var espaco = _espaco_entre_caixas()
	# Ordena por linha (posição Y, arredondada pra "linha" mais próxima) e
	# depois por posição X dentro da linha — assim a ordem de leitura
	# (de cima pra baixo, esquerda pra direita) é a ordem de execução,
	# mesmo depois de quebrar linha.
	comandos_no_trilho.sort_custom(func(a, b):
		var linha_a = roundi((a.global_position.y - trilho.global_position.y) / espaco.y)
		var linha_b = roundi((b.global_position.y - trilho.global_position.y) / espaco.y)
		if linha_a != linha_b:
			return linha_a < linha_b
		return a.global_position.x < b.global_position.x
	)

	# Quantas caixas cabem lado a lado antes de quebrar linha, baseado na
	# largura real do trilho.
	var colunas = max(1, int(trilho.size.x / espaco.x))

	for i in comandos_no_trilho.size():
		var caixa = comandos_no_trilho[i]
		var coluna = i % colunas
		var linha = i / colunas
		caixa.global_position = trilho.global_position + Vector2(coluna * espaco.x, linha * espaco.y)

	lista_montada.clear()
	for caixa in comandos_no_trilho:
		lista_montada.append(MAPA_COMANDOS.get(caixa.tipo_comando, caixa.tipo_comando))

	atualizar_texto()


func _on_comando_avancou(indice: int):
	if indice < 0 or indice >= comandos_no_trilho.size():
		$CanvasLayer/Trilho/Seta.visible = false
		return
	var caixa = comandos_no_trilho[indice]
	var centro_caixa = (caixa.global_position - trilho.global_position) + (caixa.size * caixa.scale) / 2.0
	$CanvasLayer/Trilho/Seta.position = centro_caixa + Vector2(0, -20)
	$CanvasLayer/Trilho/Seta.visible = true


func _on_b_limpar_pressed():
	if estado != Estado.JOGANDO:
		return
	$Player.interromper()
	if not comandos_no_trilho.is_empty():
		$SomCaixaRemovida.play()
	for caixa in comandos_no_trilho:
		caixa.queue_free()
	comandos_no_trilho.clear()
	lista_montada.clear()
	atualizar_texto()


func atualizar_texto():
	$CanvasLayer/Trilho/ListaComandos.text = "Comandos: %d/%d" % [comandos_no_trilho.size(), max_comandos]


func _on_objetivo_body_entered(body):
	if body != $Player:
		return
	if estado != Estado.JOGANDO:
		return
	estado = Estado.VITORIA
	$Player.interromper()
	get_tree().paused = true
	$SomAparecerPainel.play()
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
	if estado != Estado.JOGANDO or not pode_morrer:
		return
	estado = Estado.MORTO
	$Player.interromper()
	get_tree().paused = true
	$SomCancelar.play()
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
	$CanvasLayer/PainelControles.visible = false
	$Player.global_position = posicao_inicial_player
	$Player.velocity = Vector2.ZERO
	$CanvasLayer/TextoVitoria.visible = false
	$CanvasLayer/TextoDerrota.visible = false
	$CanvasLayer/BReiniciar.visible = false
	$CanvasLayer/BProximaFase.visible = false
	mostrar_caixas()
