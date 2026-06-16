extends Area2D

signal leg_collected

func _ready():
	# Connect the body_entered signal to a function
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.name == "Mite":  # Replace "Mite" with your mite's node name
		emit_signal("leg_collected")
		queue_free()  # Remove the sauterelle after collection
