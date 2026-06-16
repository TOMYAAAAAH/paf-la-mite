extends CharacterBody2D

# --- Constants ---
const GRAVITY := 980
const MAX_LAUNCH_POWER := 1000
const LAUNCH_CHARGE_SPEED := 1000
const BOUNCER_SPEED_MULTIPLIER_SM := 1.2
const BOUNCER_SPEED_MULTIPLIER_LG := 1.8
const FLOOR_SPEED_MULTIPLIER := 0.7
const DIVE_VELOCITY_MULTIPLIER := 1.1
const LAUNCH_SPEED_RATIO := 0.7
const FLOOR_SPEED_THRESHOLD := 25
const DEFAULT_JUMP_VELOCITY := -400
const DEFAULT_JUMP_SPEED := 400

# --- Node References ---
@onready var velocity_label = $VelocityLabel
@onready var jump_button = get_node("/root/Main/CanvasLayer/JumpButton")
@onready var score_label = get_node("/root/Main/CanvasLayer/ScoreLabel")
@onready var game_over_screen = get_node("/root/Main/CanvasLayer/GameOverScreen")

# --- CHARGEMENT DES FICHIERS AUDIO ---
var sound_boing_big = preload("res://boing-big.wav")
var sound_boing_small = preload("res://boing-small.wav")

# On crée des lecteurs audio directement en code pour éviter les erreurs de nœuds manquants
var jump_sound_big : AudioStreamPlayer2D
var jump_sound_small : AudioStreamPlayer2D

# --- State Variables ---
var speed = 0
var jump_velocity = 0
var leg_count = 1
var is_starting = true
var launch_power = 0
var launch_direction = 1
var is_charging = false

# --- Initialization ---
func _ready():
	_setup_audio_players()
	_setup_hopper_connections()
	_update_jump_button()
	jump_button.pressed.connect(_on_jump)

# Génération propre des lecteurs de son sans passer par l'arbre de l'éditeur
func _setup_audio_players():
	jump_sound_big = AudioStreamPlayer2D.new()
	jump_sound_big.stream = sound_boing_big
	add_child(jump_sound_big)
	
	jump_sound_small = AudioStreamPlayer2D.new()
	jump_sound_small.stream = sound_boing_small
	add_child(jump_sound_small)

func _setup_hopper_connections():
	var hoppers = get_tree().get_nodes_in_group("hopper")
	for hopper in hoppers:
		hopper.leg_collected.connect(_on_leg_collected)

# --- Physics Process ---
func _physics_process(delta):
	_apply_gravity(delta)
	_handle_floor_collision()
	_handle_launch_input(delta)
	_handle_dive_input()
	_apply_movement()
	_update_debug_label()
	_update_score_label()

# --- Gravity ---
func _apply_gravity(delta):
	if not is_on_floor():
		velocity.y += GRAVITY * delta
		jump_velocity = 0 - velocity.y

# --- Launch Input ---
func _handle_launch_input(delta):
	if is_starting:
		if Input.is_action_pressed("launch"):
			_charge_launch(delta)
		elif Input.is_action_just_released("launch") and is_charging:
			_execute_launch()
			is_charging = false
			is_starting = false

func _charge_launch(delta):
	is_charging = true
	launch_power += LAUNCH_CHARGE_SPEED * delta * launch_direction
	launch_power = clamp(launch_power, 0, MAX_LAUNCH_POWER)

	if launch_power >= MAX_LAUNCH_POWER:
		launch_direction = -1
	elif launch_power <= 0:
		launch_direction = 1

# --- Dive Input ---
func _handle_dive_input():
	if Input.is_action_just_pressed("ui_accept") and not is_on_floor():
		_on_dive()

# --- Floor Collision ---
func _handle_floor_collision():
	if is_on_floor():
		_on_floor_touched()

# --- Movement & Bouncer Collision ---
func _apply_movement():
	if not is_starting:
		velocity.x = speed
		move_and_slide()
		
		# Détection directe des groupes de bouncers sur la map
		for i in range(get_slide_collision_count()):
			var collider = get_slide_collision(i).get_collider()
			
			if collider.is_in_group("bouncer_lg"):
				_on_bouncer_lg_hit()
				break
				
			elif collider.is_in_group("bouncer_sm"):
				_on_bouncer_sm_hit()
				break

# --- Debug Label ---
func _update_debug_label():
	velocity_label.text = "Vel X: %.1f\nVel Y: %.1f\nLast Vel Y: %.1f\nLegs: %d\nLaunch Power: %d" % [velocity.x, velocity.y, jump_velocity, leg_count, launch_power]
	velocity_label.set("theme_override_colors/font_color", Color.BLACK)
	velocity_label.set("theme_override_font_sizes/font_size", 16)

# --- Launch Execution ---
func _execute_launch():
	jump_velocity = -launch_power
	velocity.y = jump_velocity
	speed = int(launch_power * LAUNCH_SPEED_RATIO)
	launch_power = 0
	
	if jump_sound_big:
		jump_sound_big.play()

# --- Leg Collection ---
func _on_leg_collected():
	leg_count += 1
	_update_jump_button()
	
	if jump_sound_small:
		jump_sound_small.play()

# --- REBOND BOUNCER PETIT ---
func _on_bouncer_sm_hit():
	jump_velocity *= BOUNCER_SPEED_MULTIPLIER_SM
	velocity.y = jump_velocity
	speed *= BOUNCER_SPEED_MULTIPLIER_SM
	
	if jump_sound_small and not jump_sound_small.playing:
		jump_sound_small.play()
		print("🔊 Rebond + Son : res://boing-small.wav")

# --- REBOND BOUNCER GROS ---
func _on_bouncer_lg_hit():
	jump_velocity *= BOUNCER_SPEED_MULTIPLIER_LG
	velocity.y = jump_velocity
	speed *= BOUNCER_SPEED_MULTIPLIER_LG
	
	if jump_sound_big and not jump_sound_big.playing:
		jump_sound_big.play()
		print("🔊 Rebond + Son : res://boing-big.wav")

# --- Dive ---
func _on_dive():
	velocity.y = abs(velocity.y) * DIVE_VELOCITY_MULTIPLIER

# --- Floor Touched ---
func _on_floor_touched():
	if abs(velocity.x) > FLOOR_SPEED_THRESHOLD:
		jump_velocity *= FLOOR_SPEED_MULTIPLIER
		velocity.y = jump_velocity
		speed *= FLOOR_SPEED_MULTIPLIER
		
		if jump_sound_big and not jump_sound_big.playing:
			jump_sound_big.play()
	else:
		speed = 0
		game_over_screen.visible = true

# --- Jump Button ---
func _update_jump_button():
	jump_button.text = "Jump (%d)" % leg_count

func _on_jump():
	if leg_count > 0:
		jump_velocity = DEFAULT_JUMP_VELOCITY
		velocity.y = jump_velocity
		speed = DEFAULT_JUMP_SPEED
		leg_count -= 1
		_update_jump_button()
		
		if jump_sound_small:
			jump_sound_small.play()
		
func _update_score_label():
	score_label.text = "Score: %.1f m" % (global_position.x/1000-0.16)
