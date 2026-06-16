extends CharacterBody2D

@onready var velocity_label = $VelocityLabel 
@onready var jump_button = get_node("/root/Main/CanvasLayer/JumpButton")  # Replace with your button's path

var speed = 0
var jump_velocity = 0
var gravity = 980
var leg_count = 1

func _ready():
	var hoppers = get_tree().get_nodes_in_group("hopper")
	for hopper in hoppers:
		hopper.leg_collected.connect(_on_leg_collected)
	
	# Initialize button text and state
	update_jump_button()
	jump_button.pressed.connect(_on_jump_button_pressed)

func _physics_process(delta):
	if not is_on_floor():
		velocity.y += gravity * delta
		jump_velocity = 0 - velocity.y

	if Input.is_action_just_pressed("launch"):
		self._on_jump_button_pressed()
	elif Input.is_action_just_pressed("ui_accept") and not is_on_floor():
		velocity.y = abs(velocity.y) * 1.1
	elif is_on_floor():
		jump_velocity *= 0.7
		velocity.y = jump_velocity
		speed *= 0.9

	# Constant forward movement
	velocity.x = speed

	# Move and get collision info
	move_and_slide()
	
	# --- SIMPLE BOUNCER TEST ---
	for i in range(get_slide_collision_count()):
		var collider = get_slide_collision(i).get_collider()
		
		if collider.is_in_group("bouncer"):
			jump_velocity *= 1.2
			velocity.y = jump_velocity
			speed *= 1.2
			
	# --- Debug Display Logic ---
	velocity_label.text = "Vel X: %.1f\nVel Y: %.1f\nLast Vel Y: %.1f\nLegs: %.1f" % [velocity.x, velocity.y, jump_velocity, leg_count]
	
	velocity_label.set("theme_override_colors/font_color", Color.WHITE)
	velocity_label.set("theme_override_font_sizes/font_size", 16)

func _on_leg_collected():
	leg_count += 1

# Update button text and state
func update_jump_button():
	jump_button.text = "Jump (%d)" % leg_count

# Handle jump button press
func _on_jump_button_pressed():
	if leg_count > 0:
		jump_velocity = -600
		velocity.y = jump_velocity
		speed = 600
		leg_count -= 1
		update_jump_button()
