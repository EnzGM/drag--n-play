extends Control

const TELA_SELECAO_FASES = "res://Scenes/Shared/selecao_fases.tscn"
const TELA_CONTROLES = "res://Scenes/Shared/controles.tscn"
const TELA_OPCOES = "res://Scenes/Shared/opcoes.tscn"
const CAMINHO_CONFIG_AUDIO = "user://opcoes.cfg"
const BUS_MASTER = "Master"
const RESOLUCAO_PADRAO := Vector2i(1152, 648)


func _ready():
	carregar_volume_salvo()
	carregar_resolucao_salva()
	for botao in [$VBoxContainer/BJogar, $VBoxContainer/BOpcoes, $VBoxContainer/BSair]:
		botao.pressed.connect(_tocar_clique_menu)
		botao.mouse_entered.connect(_tocar_hover_menu)


func _tocar_clique_menu() -> void:
	$SomCliqueMenu.play()


func _tocar_hover_menu() -> void:
	$SomHoverMenu.play()


func carregar_resolucao_salva() -> void:
	var config = ConfigFile.new()
	if config.load(CAMINHO_CONFIG_AUDIO) != OK:
		return
	var largura = int(config.get_value("video", "width", RESOLUCAO_PADRAO.x))
	var altura = int(config.get_value("video", "height", RESOLUCAO_PADRAO.y))
	get_window().size = Vector2i(largura, altura)


# Recarrega o volume salvo na tela de Opções. Roda aqui porque o Menu
# Principal é a primeira cena do jogo — assim o volume escolhido continua
# valendo mesmo depois de fechar e abrir o jogo de novo.
func carregar_volume_salvo() -> void:
	var config = ConfigFile.new()
	if config.load(CAMINHO_CONFIG_AUDIO) != OK:
		return
	var volume = clamp(config.get_value("audio", "volume", 1.0), 0.0, 1.0)
	var idx = AudioServer.get_bus_index(BUS_MASTER)
	AudioServer.set_bus_mute(idx, volume <= 0.0001)
	if volume > 0.0001:
		AudioServer.set_bus_volume_db(idx, linear_to_db(volume))


func _on_b_selecionar_fase_pressed():
	TransicaoCenas.trocar_para(TELA_SELECAO_FASES)


func _on_b_controles_pressed():
	TransicaoCenas.trocar_para(TELA_CONTROLES)


func _on_b_opcoes_pressed():
	TransicaoCenas.trocar_para(TELA_OPCOES)


func _on_b_sair_pressed():
	get_tree().quit()
