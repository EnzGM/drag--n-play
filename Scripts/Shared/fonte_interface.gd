extends Node

func _ready() -> void:
	var caminho = _encontrar_fonte("res://Assets")
	if caminho.is_empty():
		return
	var fonte = load(caminho)
	if fonte is Font:
		ThemeDB.fallback_font = fonte
		get_tree().scene_changed.connect(_aplicar_na_cena_atual.bind(fonte))
		call_deferred("_aplicar_na_cena_atual", fonte)


func _aplicar_na_cena_atual(fonte: Font) -> void:
	var cena = get_tree().current_scene
	if cena == null:
		return
	_aplicar_recursivo(cena, fonte)


func _aplicar_recursivo(no: Node, fonte: Font) -> void:
	if no is Control:
		# O override explícito vence Themes locais, inclusive menu_theme.tres.
		# Isso garante a KiwiSoda em Labels, Buttons e textos da interface.
		no.add_theme_font_override("font", fonte)
		no.add_theme_font_override("normal_font", fonte)
	for filho in no.get_children():
		_aplicar_recursivo(filho, fonte)

func _encontrar_fonte(diretorio: String) -> String:
	var dir = DirAccess.open(diretorio)
	if dir == null:
		return ""
	for arquivo in dir.get_files():
		var extensao = arquivo.get_extension().to_lower()
		if extensao in ["ttf", "otf", "ttc"]:
			return diretorio.path_join(arquivo)
	for subdiretorio in dir.get_directories():
		var encontrado = _encontrar_fonte(diretorio.path_join(subdiretorio))
		if not encontrado.is_empty():
			return encontrado
	return ""
