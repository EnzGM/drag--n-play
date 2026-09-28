extends Control

const MENU_PRINCIPAL = "res://Scenes/Shared/menu_principal.tscn"
const CAMINHO_CONFIG = "user://opcoes.cfg"
const BUS_MASTER = "Master"

@onready var slider: HSlider = $VBoxContainer/Slider
@onready var valor_volume: Label = $VBoxContainer/ValorVolume


func _ready():
	slider.value = round(volume_atual() * 100.0)
	_atualizar_label(slider.value)


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
