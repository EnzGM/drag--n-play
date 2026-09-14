extends CharacterBody2D

# --- Configurações de movimento ---
const VELOCIDADE = 300.0
const FORCA_PULO = -400.0
const GRAVIDADE = 900.0
const DISTANCIA_PASSO = 64.0

# --- Lista de comandos pra fase de execução ---
var comandos = ["andar", "pular", "andar"]
var executando = false
var interrompido = false


func _physics_process(delta):
	if not is_on_floor():
		velocity.y += GRAVIDADE * delta

	if not executando:
		if Input.is_action_pressed("ui_right"):
			velocity.x = VELOCIDADE
		elif Input.is_action_pressed("ui_left"):
			velocity.x = -VELOCIDADE
		else:
			velocity.x = 0

		if Input.is_action_just_pressed("ui_accept") and is_on_floor():
			velocity.y = FORCA_PULO

	move_and_slide()


func executar_comandos():
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
		velocity.x = VELOCIDADE if distancia > 0 else -VELOCIDADE
		await get_tree().physics_frame
	velocity.x = 0


func pular() -> void:
	if interrompido:
		return

	if is_on_floor():
		velocity.y = FORCA_PULO
		await get_tree().physics_frame

		while is_on_floor():
			if interrompido:
				return
			await get_tree().physics_frame

	while not is_on_floor():
		if interrompido:
			return
		await get_tree().physics_frame
