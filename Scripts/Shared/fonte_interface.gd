extends Node

func _ready() -> void:
	var caminho = _encontrar_fonte("res://Assets")
	if caminho.is_empty():
		return
	var fonte = load(caminho)
	if fonte is Font:
		ThemeDB.fallback_font = fonte

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
