extends Control

const MENU_PRINCIPAL = "res://Scenes/Shared/menu_principal.tscn"
const CAMINHO_CONFIG = "user://opcoes.cfg"
const BUS_MASTER = "Master"
const RESOLUCOES := [Vector2i(960, 540), Vector2i(1152, 648), Vector2i(1280, 720), Vector2i(1600, 900), Vector2i(1920, 1080)]
const RESOLUCAO_BASE := Vector2i(1152, 648)

@onready var slider: HSlider = $VBoxContainer/Slider
@onready var valor_volume: Label = $VBoxContainer/ValorVolume
@onready var seletor_resolucao: OptionButton = $VBoxContainer/SeletorResolucao
@onready var valor_resolucao: Label = $VBoxContainer/ValorResolucao


func _ready():
	slider.value = round(volume_atual() * 100.0)
	_atualizar_label(slider.value)
	for resolucao in RESOLUCOES:
		seletor_resolucao.add_item("%d x %d" % [resolucao.x, resolucao.y])
	var atual = _resolucao_salva()
	seletor_resolucao.select(_indice_resolucao(atual))
	_aplicar_resolucao(atual)


func _resolucao_salva() -> Vector2i:
	var config = ConfigFile.new()
	if config.load(CAMINHO_CONFIG) == OK:
		var largura = int(config.get_value("video", "width", 1152))
		var altura = int(config.get_value("video", "height", 648))
		return Vector2i(largura, altura)
	return Vector2i(1152, 648)


func _indice_resolucao(resolucao: Vector2i) -> int:
	for i in RESOLUCOES.size():
		if RESOLUCOES[i] == resolucao:
			return i
	return 1


func _on_resolucao_selected(indice: int) -> void:
	if indice < 0 or indice >= RESOLUCOES.size():
		return
	_aplicar_resolucao(RESOLUCOES[indice])


func _aplicar_resolucao(resolucao: Vector2i) -> void:
	# O jogo usa 1152x648 como canvas de referência e escala a HUD sem distorção.
	# DisplayServer é usado junto com Window.size para funcionar fora do editor.
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(resolucao)
	get_window().size = resolucao
	get_window().content_scale_size = RESOLUCAO_BASE
	valor_resolucao.text = "Aplicada: %d x %d" % [resolucao.x, resolucao.y]
	var config = ConfigFile.new()
	config.load(CAMINHO_CONFIG)
	config.set_value("video", "width", resolucao.x)
	config.set_value("video", "height", resolucao.y)
	config.save(CAMINHO_CONFIG)


# Lê o volume direto do bus de áudio (0.0 a 1.0), já considerando mudo.
func volume_atual() -> float:
	var idx = AudioServer.get_bus_index(BUS_MASTER)
	if AudioServer.is_bus_mute(idx):
		return 0.0
	return db_to_linear(AudioServer.get_bus_volume_db(idx))


func _on_slider_value_changed(valor: float):
	_atualizar_label(valor)
	aplicar_e_salvar_volume(valor / 100.0)


# Aplica o volume no bus (0.0 = mudo, 1.0 = volume máximo) e salva num
# arquivo de config, pra carregar de novo quando o jogo abrir na próxima vez.
func aplicar_e_salvar_volume(volume: float) -> void:
	volume = clamp(volume, 0.0, 1.0)
	var idx = AudioServer.get_bus_index(BUS_MASTER)
	AudioServer.set_bus_mute(idx, volume <= 0.0001)
	if volume > 0.0001:
		AudioServer.set_bus_volume_db(idx, linear_to_db(volume))

	var config = ConfigFile.new()
	config.set_value("audio", "volume", volume)
	config.save(CAMINHO_CONFIG)


func _atualizar_label(valor: float) -> void:
	valor_volume.text = "Volume: %d%%" % int(round(valor))


func _on_b_voltar_pressed():
	TransicaoCenas.trocar_para(MENU_PRINCIPAL)
