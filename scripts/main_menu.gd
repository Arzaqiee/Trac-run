extends Control

@onready var high_score_label: Label = $VBox/HighScoreLabel
@onready var coin_label: Label = $VBox/CoinLabel
@onready var play_button: Button = $VBox/PlayButton
@onready var skins_button: Button = $VBox/SkinsButton
@onready var shop_button: Button = $VBox/ShopButton
@onready var settings_button: Button = $VBox/SettingsButton
@onready var daily_button: Button = $VBox/DailyButton
@onready var info_dialog: AcceptDialog = $InfoDialog

func _ready() -> void:
	_refresh_labels()
	GameManager.coins_changed.connect(func(_v): _refresh_labels())
	play_button.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/Game.tscn"))
	skins_button.pressed.connect(func(): _show_info("Skins", "Menu Skins akan hadir di tahap berikutnya (Tahap 5)."))
	shop_button.pressed.connect(func(): _show_info("Shop", "Menu Shop akan hadir di tahap berikutnya (Tahap 5)."))
	settings_button.pressed.connect(func(): _show_info("Settings", "Menu Settings (music/sound) akan hadir di Tahap 6."))
	daily_button.pressed.connect(_on_daily_pressed)

func _refresh_labels() -> void:
	high_score_label.text = "High Score: %d" % GameManager.high_score
	coin_label.text = "Coin: %d" % GameManager.coins

func _on_daily_pressed() -> void:
	if GameManager.can_claim_daily_reward():
		var reward := GameManager.claim_daily_reward()
		_show_info("Daily Reward", "Kamu mendapat %d coin! (Hari ke-%d)" % [reward, GameManager.daily_reward_streak])
	else:
		_show_info("Daily Reward", "Sudah diambil hari ini. Coba lagi besok!")

func _show_info(title: String, text: String) -> void:
	info_dialog.title = title
	info_dialog.dialog_text = text
	info_dialog.popup_centered()
