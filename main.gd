extends Node2D

@onready var camera = $Mite/Camera2D
@onready var color_rect = $CanvasLayer/ProceduralBackground/ColorRect # Le chemin mis à jour avec le CanvasLayer
@onready var background_music = $BackgroundMusic

var game_started : bool = false
var initial_floor_offset : float = 0.0
var has_saved_offset : bool = false

func _ready():
	print("✅ Mode horizontal avec CanvasLayer prêt.")
	if background_music and not background_music.playing:
		background_music.play()

func _process(_delta):
	if camera and color_rect and color_rect.material is ShaderMaterial:
		var cam_pos = camera.global_position
		var mat = color_rect.material as ShaderMaterial
		
		# Le fond reste fixe sur l'écran grâce au CanvasLayer, 
		# on envoie juste la position de la caméra pour faire défiler le dessin des lignes !
		mat.set_shader_parameter("camera_x", cam_pos.x * 0.05)
		mat.set_shader_parameter("camera_y", cam_pos.y * 0.05)
		
		# Gestion du sol infini
		if game_started:
			keep_floor_infinite(cam_pos.x)

	if not game_started and Input.is_action_just_pressed("ui_focus_next"):
		start_game()

func keep_floor_infinite(camera_x: float):
	var floors = get_tree().get_nodes_in_group("floors")
	for f in floors:
		if not has_saved_offset:
			initial_floor_offset = f.global_position.x - camera_x
			has_saved_offset = true
		f.global_position.x = camera_x + initial_floor_offset

func start_game():
	game_started = true
	print("🚀 Mite propulsée !")
	var launch_sound = $Mite/sound/LaunchSound
	if launch_sound:
		launch_sound.play()

func _on_reset_button_pressed():
	get_tree().reload_current_scene()
