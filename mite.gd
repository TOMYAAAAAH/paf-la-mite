extends CharacterBody2D

@onready var velocity_label = $VelocityLabel 

var speed = 100
var jump_velocity = 0
var gravity = 980

func _physics_process(delta):
	# --- Existing Movement Logic ---
	if not is_on_floor():
		velocity.y += gravity * delta
		jump_velocity = 0 - velocity.y

	if Input.is_action_just_pressed("ui_accept"):
		jump_velocity = -600
		velocity.y = jump_velocity
		speed = 100
	elif is_on_floor():
		jump_velocity *= 0.7
		velocity.y = jump_velocity
		speed *= 0.7

	# Constant forward movement
	velocity.x = speed

	# Move and get collision info
	move_and_slide()
	
	# --- NEW: Check for Bouncer Collision ---
	for i in range(get_slide_collision_count()):
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		
		# Check if the object hit is in the "bouncer" group
		if collider.is_in_group("bouncer"):
			# Apply your custom "antwise" reaction here
			velocity.y = -700  # Strong upward boost
			velocity.x += 200  # Forward boost
			speed = velocity.x # Update speed variable to match
			# Optional: Reset decay so it doesn't slow down immediately
			jump_velocity = 0 

	# --- Debug Display Logic ---
	velocity_label.text = "Vel X: %.1f\nVel Y: %.1f\nLast Vel Y: %.1f" % [velocity.x, velocity.y, jump_velocity]
	
	velocity_label.set("theme_override_colors/font_color", Color.WHITE)
	velocity_label.set("theme_override_font_sizes/font_size", 16)
