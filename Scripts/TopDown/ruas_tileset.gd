extends TileMap

# Cada célula jogável tem 100 px. O atlas usa tiles de 16 px; dois por dois
# formam um bloco de 32 px, ampliado para 100 px sem abandonar o TileMap.
const ESCALA_BLOCO := 3.125
const ORIGEM_MUNDO := Vector2(-50, -50)
const SOURCE_ID := 1

# O atlas foi organizado em grupos 2x2: cantos, bordas e variações internas.
const MAPA_BLOCOS := [
	[Vector2i(4, 4), Vector2i(7, 1), Vector2i(4, 1), Vector2i(7, 1), Vector2i(10, 4)],
	[Vector2i(4, 1),  Vector2i(7, 1), Vector2i(10, 1), Vector2i(7, 1), Vector2i(4, 1)],
	[Vector2i(4, 7),  Vector2i(7, 7), Vector2i(10, 7), Vector2i(7, 7), Vector2i(4, 7)],
	[Vector2i(4, 1),  Vector2i(10, 1), Vector2i(7, 1), Vector2i(10, 1), Vector2i(4, 1)],
	[Vector2i(4, 7), Vector2i(7, 7), Vector2i(4, 7), Vector2i(7, 7), Vector2i(10, 7)],
]

func _ready() -> void:
	position = ORIGEM_MUNDO
	scale = Vector2(ESCALA_BLOCO, ESCALA_BLOCO)
	z_index = -8
	clear()

	for y in MAPA_BLOCOS.size():
		for x in MAPA_BLOCOS[y].size():
			_pintar_bloco(Vector2i(x * 2, y * 2), MAPA_BLOCOS[y][x])

	# Continuação da estrada até a saída da fase.
	_pintar_bloco(Vector2i(4, 10), Vector2i(7, 1))
	_pintar_bloco(Vector2i(4, 12), Vector2i(7, 1))

func _pintar_bloco(posicao: Vector2i, atlas_inicio: Vector2i) -> void:
	for y in 2:
		for x in 2:
			set_cell(0, posicao + Vector2i(x, y), SOURCE_ID, atlas_inicio + Vector2i(x, y), 0)
