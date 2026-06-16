extends Node2D

# On pointe sur la caméra embarquée dans ton personnage "Mite"
@onready var camera = $Mite/Camera2D
@onready var color_rect = $ProceduralBackground/ColorRect

# Ajout du nœud pour la musique de fond
@onready var background_music = $BackgroundMusic

func _ready():
	# Check de sécurité au lancement du jeu
	if camera == null:
		print("❌ ERREUR : Impossible de trouver la Camera2D sous $Mite. Vérifie l'arbre de scène !")
	else:
		print("✅ Système de défilement initialisé pour Mite.")
	
	# Lancement de la musique de fond si elle n'est pas déjà active
	if background_music and not background_music.playing:
		background_music.play()

func _process(_delta):
	# Si la caméra et le fond sont valides, on met à jour les coordonnées du shader
	if camera and color_rect and color_rect.material is ShaderMaterial:
		var cam_pos = camera.global_position
		var mat = color_rect.material as ShaderMaterial
		
		# On envoie les positions X et Y au shader
		mat.set_shader_parameter("camera_x", cam_pos.x)
		mat.set_shader_parameter("camera_y", cam_pos.y)

# Gestion du bouton de Reset
func _on_reset_button_pressed():
	get_tree().reload_current_scene()
