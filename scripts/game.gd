extends Node2D
## Controller scene gameplay utama (Game.tscn).

@onready var player: CharacterBody2D = $Player
@onready var spawner: Node2D = $Spawner
@onready var bg_layer1: ParallaxLayer = $Background/ParallaxLayer1
@onready var bg_layer2: ParallaxLayer = $Background/ParallaxLayer2

@onready var score_label: Label = $UI/TopBar/ScoreLabel
@onready var coin_label: Label = $UI/TopBar/CoinLabel
@onready var combo_label: Label = $UI/TopBar/ComboLabel
@onready var difficulty_label: Label = $UI/TopBar/DifficultyLabel
@onready var pause_button: Button = $UI/PauseButton

@onready var pause_menu: CanvasLayer = $PauseMenu
@onready var game_over_menu: CanvasLayer = $GameOverMenu
@onready var go_score_value: Label = $GameOverMenu/Panel/VBox/ScoreValue
@onready var go_coins_value: Label = $GameOverMenu/Panel/VBox/CoinsValue
@onready var go_best_value: Label = $GameOverMenu/Panel/VBox/BestValue
@onready var go_new_high: Label = $GameOverMenu/Panel/VBox/NewHighLabel

var _magnet_active := false
var _coin2x_active := false
var _slowmo_active := false
var _magnet_timer := 0.0
var _coin2x_timer := 0.0
var _slowmo_timer := 0.0

func _ready() -> void:
	GameManager.start_new_run()
	spawner.set_player(player)
	spawner.ground_y = player.position.y
	player.died.connect(_on_player_died)
	pause_menu.visible = false
	game_over_menu.visible = false
	pause_button.pressed.connect(_toggle_pause)
	spawner.powerup_collected.connect(_on_powerup_collected)

func _physics_process(delta: float) -> void:
	if not player.is_alive:
		return

	var speed: float = 500.0 * GameManager.get_speed_multiplier()
	if _slowmo_active:
		speed *= 0.45

	GameManager.add_distance(speed * delta)

	bg_layer1.motion_offset.x -= speed * delta * 0.5
	bg_layer2.motion_offset.x -= speed * delta * 0.9

	_update_hud()
	_update_powerup_timers(delta)
	_apply_magnet_to_coins()

func _update_hud() -> void:
	score_label.text = "Score: %d" % GameManager.run_score
	coin_label.text = "Coin: %d" % GameManager.run_coins
	combo_label.text = "Combo: x%d" % GameManager.run_combo
	difficulty_label.text = GameManager.get_difficulty_name()

func _update_powerup_timers(delta: float) -> void:
	if _magnet_active:
		_magnet_timer -= delta
		if _magnet_timer <= 0:
			_magnet_active = false
	if _coin2x_active:
		_coin2x_timer -= delta
		if _coin2x_timer <= 0:
			_coin2x_active = false
			spawner.coin_multiplier = 1
	if _slowmo_active:
		_slowmo_timer -= delta
		if _slowmo_timer <= 0:
			_slowmo_active = false

func _apply_magnet_to_coins() -> void:
	if not _magnet_active:
		return
	for child in spawner.get_children():
		if child.has_method("set_magnet_target") and child.global_position.distance_to(player.global_position) < 500.0:
			child.set_magnet_target(player)

func _on_powerup_collected(power_type: String) -> void:
	match power_type:
		"magnet":
			_magnet_active = true
			_magnet_timer = 6.0
		"shield":
			player.activate_shield()
		"coin2x":
			_coin2x_active = true
			_coin2x_timer = 8.0
			spawner.coin_multiplier = 2
		"slowmo":
			_slowmo_active = true
			_slowmo_timer = 4.0

func _on_player_died() -> void:
	GameManager.end_run()
	go_score_value.text = str(GameManager.run_score)
	go_coins_value.text = str(GameManager.run_coins)
	go_best_value.text = str(GameManager.high_score)
	go_new_high.visible = GameManager.is_new_high_score()
	game_over_menu.visible = true
	get_tree().paused = true

func _toggle_pause() -> void:
	get_tree().paused = not get_tree().paused
	pause_menu.visible = get_tree().paused

func _on_resume_pressed() -> void:
	get_tree().paused = false
	pause_menu.visible = false

func _on_restart_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_home_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

func _on_retry_pressed() -> void:
	get_tree().reload_current_scene()
