extends CharacterBody2D

# --- Configurações de movimento ---
const VELOCIDADE_CHAO = 400.0
const VELOCIDADE_AR = 320.0
const FORCA_PULO = -400.0
const GRAVIDADE = 900.0
const DISTANCIA_PASSO = 144.0
const DISTANCIA_PULO = 160.0  # quanto ele anda pra frente durante UM pulo completo

# --- Lista de comandos pra fase de execução ---
var comandos = ["andar", "pular", "andar"]
var executando = false
var interrompido = false

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready():
	# As plataformas da fase_1 (os montinhos com o guarda-chuva) usam
	# colisão arredondada (CapsuleShape2D), não um chão reto. Com o
	# ângulo máximo padrão de chão (45°), assim que você sai do topo bem
	# no centro da curva, is_on_floor() já passa a dar "false" — e como
	# pular() checa "if not is_on_floor(): return", o pulo simplesmente
	# não acontecia (sem erro nenhum) depois de andar até uma posição
	# fora desse centro exato. Aumentando esse ângulo, a maior parte da
	# curva ainda conta como chão.
	floor_max_angle = deg_to_rad(80.0)
	# Além disso, o pé do personagem TAMBÉM é uma cápsula arredondada —
	# redondo encostando em redondo é um contato instável (às vezes é só
	# um pontinho, não uma área), e o motor de física pode não registrar
	# isso como "no chão" de forma confiável. Esse "snap" aumenta a
	# tolerância pra manter o contato mesmo com essa instabilidade.
	floor_snap_length = 16.0


func _physics_process(delta):
	# O nó da fase (raiz) roda com process_mode = Always, pra o botão de
	# Reiniciar funcionar mesmo pausado — mas isso também faz o Player
	# (que herda esse modo) continuar recebendo física normalmente
	# mesmo com get_tree().paused = true. Esse "return" aqui é quem
	# efetivamente congela o personagem enquanto o jogo tá pausado
	# (morte, vitória ou menu de pausa).
	if get_tree().paused:
		return

	if not is_on_floor():
		velocity.y += GRAVIDADE * delta

	if not executando:
		var velocidade_atual = VELOCIDADE_CHAO if is_on_floor() else VELOCIDADE_AR
		if Input.is_action_pressed("ui_right"):
			velocity.x = velocidade_atual
		elif Input.is_action_pressed("ui_left"):
			velocity.x = -velocidade_atual
		else:
			velocity.x = 0

		if Input.is_action_just_pressed("ui_accept") and is_on_floor():
			velocity.y = FORCA_PULO

	move_and_slide()
	atualizar_animacao()


func atualizar_animacao():
	# Enquanto tiver velocidade horizontal (andando ou pulando pra algum
	# lado), toca a animação de andar e vira o sprite pro lado certo.
	# Parado (ou caindo reto), fica no idle.
	if abs(velocity.x) > 1.0:
		sprite.flip_h = velocity.x < 0
		sprite.play("andar")
	else:
		sprite.play("idle")


func executar_comandos():
	# Se já tá executando uma sequência, ignora a chamada em vez de reiniciar
	# tudo do zero por cima — é o que causava o "andar infinito", quando
	# executar_comandos() era chamado de novo no meio de uma execução.
	if executando:
		return

	executando = true
	interrompido = false

	for comando in comandos:
		if interrompido:
			break
		match comando:
			"andar":
				await andar(DISTANCIA_PASSO)
			"andar_tras":
				await andar(-DISTANCIA_PASSO)
			"pular":
				await pular()
			"esperar":
				await get_tree().create_timer(1.0).timeout

	velocity.x = 0
	executando = false


func interromper():
	interrompido = true


func andar(distancia: float) -> void:
	var alvo_x = global_position.x + distancia
	var direcao = sign(distancia)
	# Antes a condição de parada era só "abs(distância) > 2.0", com a
	# velocidade sempre na mesma direção. Se um frame passasse do alvo por
	# mais de 2px (fácil de acontecer com velocidade alta), o loop
	# continuava "true" do outro lado e o personagem nunca mais parava —
	# andava pra longe do alvo pra sempre. Agora a condição é "ainda não
	# cheguei nem passei do alvo", que para corretamente mesmo com
	# overshoot.
	while (global_position.x - alvo_x) * direcao < 0:
		if interrompido:
			return
		var velocidade_atual = VELOCIDADE_CHAO if is_on_floor() else VELOCIDADE_AR
		velocity.x = velocidade_atual * direcao
		await get_tree().physics_frame
	global_position.x = alvo_x  # encaixa exatamente no alvo, sem sobra de overshoot
	velocity.x = 0


func pular() -> void:
	if interrompido:
		return
	if not is_on_floor():
		print("PULAR CANCELADO: is_on_floor()=false, posição=%s, velocity=%s" % [global_position, velocity])
		return

	# Tempo total que o personagem fica no ar num pulo completo (sobe e desce
	# até a mesma altura), calculado a partir da física (v = g*t na subida).
	var tempo_no_ar = (2.0 * abs(FORCA_PULO)) / GRAVIDADE
	# Velocidade horizontal necessária pra percorrer DISTANCIA_PULO nesse
	# tempo — assim o pulo tem um alcance fixo e previsível, em vez de
	# deslizar na VELOCIDADE_AR (rápida) pelo quase 1 segundo inteiro que
	# fica no ar, o que fazia o pulo parecer só um andar comprido.
	var velocidade_horizontal_pulo = DISTANCIA_PULO / tempo_no_ar

	velocity.y = FORCA_PULO
	velocity.x = velocidade_horizontal_pulo
	await get_tree().physics_frame

	# Garante que o personagem realmente saiu do chão antes de considerar
	# que ele pousou. Sem isso, "is_on_floor()" ainda podia estar true
	# nesse primeiro frame (o contato antigo com o chão não tinha
	# atualizado ainda), o loop de baixo (que espera pousar) nunca
	# rodava, e o "pular" terminava na hora — o próximo comando (andar)
	# começava com o personagem ainda no ar, parecendo que ele só andou.
	while is_on_floor():
		if interrompido:
			return
		velocity.x = velocidade_horizontal_pulo
		await get_tree().physics_frame

	while not is_on_floor():
		if interrompido:
			return
		velocity.x = velocidade_horizontal_pulo
		await get_tree().physics_frame

	velocity.x = 0
