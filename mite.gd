extends CharacterBody2D

# --- Constants ---
const GRAVITY := 980
const MAX_LAUNCH_POWER := 1000
const LAUNCH_CHARGE_SPEED := 1000
const BOUNCER_SPEED_MULTIPLIER := 1.2
const FLOOR_SPEED_MULTIPLIER := 0.7
const DIVE_VELOCITY_MULTIPLIER := 1.1
const LAUNCH_SPEED_RATIO := 0.7
const FLOOR_SPEED_THRESHOLD := 25
const DEFAULT_JUMP_VELOCITY := -400
const DEFAULT_JUMP_SPEED := 400

# --- Node References ---
@onready var velocity_label = $VelocityLabel
@onready var jump_button = get_node("/root/Main/CanvasLayer/JumpButton")

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
	_setup_hopper_connections()
	_setup_bouncer_connections()
	_update_jump_button()
	jump_button.pressed.connect(_on_jump)

func _setup_hopper_connections():
	var hoppers = get_tree().get_nodes_in_group("hopper")
	for hopper in hoppers:
		hopper.leg_collected.connect(_on_leg_collected)

func _setup_bouncer_connections():  # NEW
	var bouncers = get_tree().get_nodes_in_group("bouncer")
	for bouncer in bouncers:
		bouncer.bouncer_sm_hit.connect(_on_bouncer_sm_hit)

# --- Physics Process ---
func _physics_process(delta):
	_apply_gravity(delta)
	_handle_launch_input(delta)
	_handle_dive_input()
	_handle_floor_collision()
	_apply_movement()
	_update_debug_label()

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

# --- Movement ---
func _apply_movement():
	if not is_starting:
		velocity.x = speed
		move_and_slide()

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

# --- Leg Collection ---
func _on_leg_collected():
	leg_count += 1
	_update_jump_button()
	
func _on_bouncer_sm_hit():
	jump_velocity *= BOUNCER_SPEED_MULTIPLIER
	velocity.y = jump_velocity
	speed *= BOUNCER_SPEED_MULTIPLIER

# --- Dive ---
func _on_dive():
	velocity.y = abs(velocity.y) * DIVE_VELOCITY_MULTIPLIER

# --- Floor Touched ---
func _on_floor_touched():
	if abs(velocity.x) > FLOOR_SPEED_THRESHOLD:
		jump_velocity *= FLOOR_SPEED_MULTIPLIER
		velocity.y = jump_velocity
		speed *= FLOOR_SPEED_MULTIPLIER
	else:
		speed = 0

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
