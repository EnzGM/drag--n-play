extends CanvasLayer

const DURACAO_FADE := 0.28
var cobertura: ColorRect
var trocando := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 200
	cobertura = ColorRect.new()
	cobertura.name = "FadeOverlay"
	cobertura.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cobertura.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cobertura.color = Color(0.015, 0.01, 0.04, 1.0)
	add_child(cobertura)
	get_tree().scene_changed.connect(_on_scene_changed)
	await get_tree().process_frame
	_fade_in()

func _on_scene_changed() -> void:
	_fade_in()

func _fade_in() -> void:
	if not is_instance_valid(cobertura):
		return
	cobertura.mouse_filter = Control.MOUSE_FILTER_IGNORE
	create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).tween_property(
		cobertura, "color", Color(0.015, 0.01, 0.04, 0.0), DURACAO_FADE
	)

func trocar_para(caminho: String) -> void:
	if trocando or caminho.is_empty():
		return
	trocando = true
	get_tree().paused = false
	cobertura.mouse_filter = Control.MOUSE_FILTER_STOP
	var tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(cobertura, "color", Color(0.015, 0.01, 0.04, 1.0), DURACAO_FADE)
	await tween.finished
	get_tree().change_scene_to_file(caminho)
	trocando = false
