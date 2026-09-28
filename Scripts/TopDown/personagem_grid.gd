extends Node2D

enum Direcao { CIMA, BAIXO, ESQUERDA, DIREITA }

const TEMPO_MOVIMENTO = 0.18  # duração da animação de deslizar uma célula
const TEMPO_ATAQUE = 0.15

var comandos = []
var executando = false
var interrompido = false
var direcao_atual: int = Direcao.BAIXO
var celula: Vector2i = Vector2i.ZERO

# Setado pela fase em _ready(): precisa expor celula_e_parede(), 
# celula_tem_inimigo_vivo(), tentar_derrotar_inimigo(), posicao_da_celula(),
# jogador_morreu() e jogador_venceu().
var fase = null

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var seta: Node2D = $Seta
@onready var som_passo: Array[AudioStreamPlayer] = [$SomPasso1, $SomPasso2]

var _indice_passo = 0


signal comando_avancou(indice)

func interromper():
	interrompido = true


func executar_comandos():
	# Se já tá executando, ignora a chamada em vez de reiniciar tudo do
	# zero por cima (mesmo cuidado que o personagem da plataforma tem).
	if executando:
		return

	executando = true
	interrompido = false

	for i in comandos.size():
		if interrompido:
			break
		comando_avancou.emit(i)
		match comandos[i]:
			"cima":
				await mover(Direcao.CIMA)
			"baixo":
				await mover(Direcao.BAIXO)
			"esquerda":
				await mover(Direcao.ESQUERDA)
			"direita":
				await mover(Direcao.DIREITA)
			"atacar":
				await atacar()

	executando = false
	comando_avancou.emit(-1)


func vetor_direcao(dir: int) -> Vector2i:
	match dir:
		Direcao.CIMA:
			return Vector2i(0, -1)
		Direcao.BAIXO:
			return Vector2i(0, 1)
		Direcao.ESQUERDA:
			return Vector2i(-1, 0)
		Direcao.DIREITA:
			return Vector2i(1, 0)
	return Vector2i.ZERO


func virar(dir: int) -> void:
	direcao_atual = dir
	if sprite and sprite.sprite_frames:
		match dir:
			Direcao.CIMA:
				sprite.play("cima")
			Direcao.BAIXO:
				sprite.play("baixo")
			Direcao.ESQUERDA:
				sprite.play("esquerda")
			Direcao.DIREITA:
				sprite.play("direita")
	if seta:
		# Enquanto não tiver sprite com animação por direção, essa
		# setinha já mostra pra onde o personagem tá olhando.
		seta.rotation = Vector2(vetor_direcao(dir)).angle()


func mover(dir: int) -> void:
	if interrompido:
		return
	virar(dir)

	var alvo = celula + vetor_direcao(dir)

	if fase.celula_e_parede(alvo):
		# Bateu na parede: fica de frente pra ela, não anda.
		$SomBloqueado.play()
		return

	if fase.has_method("celula_bloqueada_especial") and fase.celula_bloqueada_especial(alvo):
		# O cadeado impede a passagem até a chave ser coletada.
		return

	if fase.celula_tem_inimigo_vivo(alvo):
		# Andou em cima de um inimigo sem atacar antes.
		fase.jogador_morreu()
		return

	celula = alvo
	var posicao_alvo = fase.posicao_da_celula(celula)

	som_passo[_indice_passo].play()
	_indice_passo = (_indice_passo + 1) % som_passo.size()

	var tween = create_tween()
	tween.tween_property(self, "global_position", posicao_alvo, TEMPO_MOVIMENTO)
	await tween.finished

	if interrompido:
		return

	if fase.has_method("jogador_entrou_na_celula"):
		fase.jogador_entrou_na_celula(celula)

	if fase.celula_e_objetivo(celula):
		fase.jogador_venceu()


func atacar() -> void:
	if interrompido:
		return
	$SomAtacar.play()
	var alvo = celula + vetor_direcao(direcao_atual)
	fase.tentar_derrotar_inimigo(alvo)
	await get_tree().create_timer(TEMPO_ATAQUE).timeout
