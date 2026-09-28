extends Node2D

enum Estado { JOGANDO, MORTO, VITORIA }

const TAMANHO_CELULA = 100.0
# Folga (em pixels) entre uma caixa e outra no trilho. O espaço total é o
# tamanho real da caixa + essa folga, então dá pra apertar ou afrouxar aqui.
const FOLGA_ENTRE_CAIXAS = 8.0   # lado a lado (horizontal)
const FOLGA_ENTRE_LINHAS = 6.0   # entre linhas (vertical)

# Converte o "tipo_comando" da caixa pro comando que o Player entende.
const MAPA_COMANDOS = {
	"cima": "cima",
	"baixo": "baixo",
	"esquerda": "esquerda",
	"direita": "direita",
	"atacar": "atacar",
}

var lista_montada = []
var comandos_no_trilho = []  # guarda as caixas (nós), na ordem em que aparecem
var celula_inicial_player: Vector2i
var estado = Estado.JOGANDO
var ja_executou = false  # trava o play depois do primeiro uso, até reiniciar
var menu_aberto = false

var paredes: Dictionary = {}   # Vector2i -> true
var inimigos: Dictionary = {}  # Vector2i -> nó do inimigo (pra poder remover ao derrotar)
var inimigos_originais: Dictionary = {}  # Vector2i -> cópia "molde", pra repor ao reiniciar
var celula_objetivo: Vector2i

@export var usar_limites_grade: bool = false
@export var limites_grade: Rect2i = Rect2i(-9999, -9999, 19999, 19999)
@export var tem_chave: bool = false
@export var celula_chave: Vector2i = Vector2i.ZERO
@export var celula_cadeado: Vector2i = Vector2i.ZERO
@export var celula_saida: Vector2i = Vector2i.ZERO
var chave_coletada: bool = false

# Caminho da cena da próxima fase. Deixe em branco se a fase não tiver
# "próxima". Preenche no Inspector do nó raiz, sem precisar mexer em código.
@export_file("*.tscn") var proxima_fase: String = ""

# Texto do tutorial mostrado ao entrar na fase (pausado, com botão "Entendi").
@export_multiline var texto_tutorial: String = ""

# Imagem opcional mostrada junto do texto do tutorial.
@export var imagem_tutorial: Texture2D = null

# Quantas caixas cabem no trilho.
@export var max_comandos: int = 7

# Se false, andar em cima de um inimigo vivo não mata — pra uma eventual
# fase-tutorial desse modo, sem risco.
@export var pode_morrer: bool = true

# Se true, dá pra apertar Play quantas vezes quiser sem precisar reiniciar.
@export var permitir_repetir: bool = false

@onready var trilho: Control = $CanvasLayer/Trilho


func _ready():
	$CanvasLayer.visible = true
	$Player.comando_avancou.connect(_on_comando_avancou)
	mostrar_caixas()
	atualizar_texto()
	queue_redraw()

	for parede in $Paredes.get_children():
		paredes[celula_da_posicao(parede.position)] = true

	for inimigo in $Inimigos.get_children():
		var c = celula_da_posicao(inimigo.position)
		inimigos[c] = inimigo
		inimigos_originais[c] = inimigo.duplicate()

	celula_objetivo = celula_da_posicao($Objetivo.position)

	chave_coletada = false
	atualizar_visual_chave_cadeado()
	if has_node("CanvasLayer/TextoChave"):
		$CanvasLayer/TextoChave.text = ""
		$CanvasLayer/TextoChave.visible = false

	celula_inicial_player = celula_da_posicao($Player.position)
	$Player.fase = self
	$Player.celula = celula_inicial_player

	if not texto_tutorial.is_empty():
		$CanvasLayer/PainelTutorial/Conteudo/Rolagem/Label.text = texto_tutorial
		$CanvasLayer/PainelTutorial/Conteudo/Imagem.texture = imagem_tutorial
		$CanvasLayer/PainelTutorial/Conteudo/Imagem.visible = imagem_tutorial != null
		$CanvasLayer/PainelTutorial.visible = true
		$SomAparecerPainel.play()
		get_tree().paused = true
	else:
		if has_node("CanvasLayer/PainelTutorial"):
			$CanvasLayer/PainelTutorial.visible = false


# --- Ponte com o personagem_grid.gd ---

func _draw() -> void:
	# Desenha as linhas da grade sobre a área do Fundo, uma célula por
	# quadrado — puramente visual, não afeta a lógica de colisão.
	if not has_node("Fundo"):
		return
	var fundo: ColorRect = $Fundo
	var esquerda = fundo.position.x
	var topo = fundo.position.y
	var direita = fundo.position.x + fundo.size.x
	var baixo = fundo.position.y + fundo.size.y
	var cor_grade = Color(0, 0, 0, 0.3)

	var x = esquerda
	while x <= direita + 0.5:
		draw_line(Vector2(x, topo), Vector2(x, baixo), cor_grade, 2.0)
		x += TAMANHO_CELULA

	var y = topo
	while y <= baixo + 0.5:
		draw_line(Vector2(esquerda, y), Vector2(direita, y), cor_grade, 2.0)
		y += TAMANHO_CELULA


func celula_da_posicao(pos: Vector2) -> Vector2i:
	return Vector2i(roundi(pos.x / TAMANHO_CELULA), roundi(pos.y / TAMANHO_CELULA))


func posicao_da_celula(celula: Vector2i) -> Vector2:
	return Vector2(celula.x * TAMANHO_CELULA, celula.y * TAMANHO_CELULA)


func celula_e_parede(celula: Vector2i) -> bool:
	if paredes.has(celula):
		return true
	if usar_limites_grade and not limites_grade.has_point(celula):
		if celula == celula_cadeado or celula == celula_saida:
			return false
		return true
	return false


func celula_bloqueada_especial(celula: Vector2i) -> bool:
	if tem_chave and celula == celula_cadeado and not chave_coletada:
		if has_node("SomCancelar"):
			$SomCancelar.play()
		return true
	return false


func jogador_entrou_na_celula(celula: Vector2i) -> void:
	if tem_chave and not chave_coletada and celula == celula_chave:
		chave_coletada = true
		if has_node("SomChave"):
			$SomChave.play()
		atualizar_visual_chave_cadeado()
		if has_node("CanvasLayer/TextoChave"):
			$CanvasLayer/TextoChave.text = "CHAVE: PEGOU ✓"
			$CanvasLayer/TextoChave.visible = true


func atualizar_visual_chave_cadeado() -> void:
	if has_node("Chave"):
		$Chave.visible = tem_chave and not chave_coletada
	if has_node("Cadeado"):
		$Cadeado.visible = not chave_coletada


func celula_tem_inimigo_vivo(celula: Vector2i) -> bool:
	return inimigos.has(celula)


func celula_e_objetivo(celula: Vector2i) -> bool:
	return celula == celula_objetivo


func tentar_derrotar_inimigo(celula: Vector2i) -> void:
	if inimigos.has(celula):
		var inimigo = inimigos[celula]
		inimigo.queue_free()
		inimigos.erase(celula)
		$SomCaixaRemovida.play()  # reaproveitado como "poof" do inimigo sumindo


func jogador_morreu() -> void:
	if estado != Estado.JOGANDO or not pode_morrer:
		return
	estado = Estado.MORTO
	$Player.interromper()
	get_tree().paused = true
	$SomCancelar.play()
	$CanvasLayer/TextoDerrota.visible = true
	$CanvasLayer/BReiniciar.visible = true


func jogador_venceu() -> void:
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


# --- Daqui pra baixo é a mesma estrutura de UI da fase_teste.gd ---

func _on_b_entendi_pressed():
	$CanvasLayer/PainelTutorial.visible = false
	if estado == Estado.JOGANDO:
		get_tree().paused = false


func _input(event):
	if not (event is InputEventKey) or not event.pressed or event.is_echo():
		return

	if event.keycode == KEY_ESCAPE:
		alternar_menu_pausa()
		return

	if event.keycode == KEY_R:
		reiniciar_fase()
		return

	if menu_aberto or estado != Estado.JOGANDO:
		return

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
	if not has_node("CanvasLayer/PainelControles"):
		return
	$CanvasLayer/MenuPausa.visible = false
	$CanvasLayer/PainelControles.visible = true
	$SomAparecerPainel.play()


func _on_b_controles_voltar_pressed():
	if not has_node("CanvasLayer/PainelControles"):
		return
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
		posicionar_player_no_inicio()
		ja_executou = false
		mostrar_caixas()
		return

	if estado == Estado.JOGANDO:
		$CanvasLayer/BReiniciar.visible = true


func _on_b_play_pressed():
	iniciar_execucao()


func esconder_caixas():
	# Só esconde a paleta — as caixas do trilho ficam visíveis durante a
	# execução, pra dar pra ver a setinha indicando qual comando tá rodando.
	$CanvasLayer/Caixas.visible = false


func mostrar_caixas():
	$CanvasLayer/Caixas.visible = true


func soltar_caixa(caixa):
	if estado != Estado.JOGANDO:
		return

	var centro = caixa.global_position + (caixa.size * caixa.scale) / 2.0
	var dentro_do_trilho = trilho.get_global_rect().has_point(centro)

	if dentro_do_trilho:
		if not comandos_no_trilho.has(caixa):
			if comandos_no_trilho.size() >= max_comandos:
				$SomCancelar.play()
				caixa.queue_free()
				return
			$SomCaixaEncaixada.play()
			comandos_no_trilho.append(caixa)
	else:
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
	# As caixas ficam menores quando entram no trilho, permitindo montar uma
	# sequência de até 7 comandos sem estourar a largura do painel.
	var escala_trilho = 0.55
	for caixa in comandos_no_trilho:
		caixa.scale = Vector2(escala_trilho, escala_trilho)

	var espaco = _espaco_entre_caixas()
	comandos_no_trilho.sort_custom(func(a, b):
		var linha_a = roundi((a.global_position.y - trilho.global_position.y) / espaco.y)
		var linha_b = roundi((b.global_position.y - trilho.global_position.y) / espaco.y)
		if linha_a != linha_b:
			return linha_a < linha_b
		return a.global_position.x < b.global_position.x
	)

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


func _on_b_reiniciar_pressed():
	reiniciar_fase()


func posicionar_player_no_inicio() -> void:
	$Player.interromper()
	$Player.executando = false
	$Player.virar($Player.Direcao.BAIXO)
	$Player.celula = celula_inicial_player
	$Player.global_position = posicao_da_celula(celula_inicial_player)

	# Repõe os inimigos derrotados durante essa tentativa.
	for celula in inimigos_originais.keys():
		if not inimigos.has(celula):
			var novo = inimigos_originais[celula].duplicate()
			$Inimigos.add_child(novo)
			novo.position = posicao_da_celula(celula)
			inimigos[celula] = novo


func reiniciar_fase():
	posicionar_player_no_inicio()
	ja_executou = false
	$CanvasLayer/BPlay.disabled = false

	for caixa in comandos_no_trilho:
		caixa.queue_free()
	comandos_no_trilho.clear()
	lista_montada.clear()
	atualizar_texto()

	get_tree().paused = false
	estado = Estado.JOGANDO
	chave_coletada = false
	if has_node("CanvasLayer/TextoChave"):
		$CanvasLayer/TextoChave.text = ""
		$CanvasLayer/TextoChave.visible = false
	atualizar_visual_chave_cadeado()
	menu_aberto = false
	$CanvasLayer/MenuPausa.visible = false
	if has_node("CanvasLayer/PainelControles"):
		$CanvasLayer/PainelControles.visible = false
	$CanvasLayer/TextoVitoria.visible = false
	$CanvasLayer/TextoDerrota.visible = false
	$CanvasLayer/BReiniciar.visible = false
	$CanvasLayer/BProximaFase.visible = false
	mostrar_caixas()
