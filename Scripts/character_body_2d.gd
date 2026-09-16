extends CharacterBody2D

# --- Configurações de movimento ---
const VELOCIDADE_CHAO = 400.0
const VELOCIDADE_AR = 320.0
const FORCA_PULO = -400.0
const GRAVIDADE = 900.0
const DISTANCIA_PASSO = 64.0
const DISTANCIA_PULO = 96.0  # quanto ele anda pra frente durante UM pulo completo

# --- Lista de comandos pra fase de execução ---
var comandos = ["andar", "pular", "andar"]
var executando = false
var interrompido = false


func _physics_process(delta):
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
	while abs(global_position.x - alvo_x) > 2.0:
		if interrompido:
			return
		var velocidade_atual = VELOCIDADE_CHAO if is_on_floor() else VELOCIDADE_AR
		velocity.x = velocidade_atual if distancia > 0 else -velocidade_atual
		await get_tree().physics_frame
	velocity.x = 0


func pular() -> void:
	if interrompido:
		return
	if not is_on_floor():
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
