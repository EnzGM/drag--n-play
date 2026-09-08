extends CharacterBody2D

# --- Configurações de movimento ---
const VELOCIDADE = 200.0       # velocidade horizontal (pixels por segundo)
const FORCA_PULO = -400.0      # força do pulo (negativo porque "pra cima" é negativo no Godot)
const GRAVIDADE = 900.0        # o quanto a gravidade puxa o personagem pra baixo

# --- Lista de comandos pra fase de execução ---
var comandos = ["andar", "pular", "andar"]  # sequência de teste
var executando = false                       # controla se está no modo "execução automática"

func _physics_process(delta):
	# Aplica gravidade sempre, esteja executando ou não
	if not is_on_floor():
		velocity.y += GRAVIDADE * delta

	# Se NÃO estiver executando a sequência automática, deixa o jogador controlar manualmente
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


# --- Função que executa a lista de comandos, um de cada vez ---
func executar_comandos():
	executando = true  # trava o controle manual enquanto executa

	for comando in comandos:
		match comando:
			"andar":
				await andar(1.0)  # anda por 1 segundo
			"pular":
				await pular()
			"esperar":
				await get_tree().create_timer(1.0).timeout

	# Terminou a sequência: para o personagem e libera o controle de novo (se quiser)
	velocity.x = 0
	executando = false


# --- Ação: andar por um tempo determinado ---
func andar(tempo: float) -> void:
	velocity.x = VELOCIDADE
	await get_tree().create_timer(tempo).timeout
	velocity.x = 0


# --- Ação: pular e esperar até tocar o chão de novo ---
func pular() -> void:
	if is_on_floor():
		velocity.y = FORCA_PULO
	
	# Espera até o personagem tocar o chão de novo antes de seguir pro próximo comando
	while not is_on_floor():
		await get_tree().process_frame
