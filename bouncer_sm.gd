extends Area2D

signal bouncer_sm_hit

@onready var collision_shape = $CollisionShape2D

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.name == "Mite":
		emit_signal("bouncer_sm_hit")
		collision_shape.disabled = true
