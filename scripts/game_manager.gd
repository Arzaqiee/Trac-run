extends Node
## GameManager (Autoload)
## Menyimpan state global: coin, high score, skin aktif, setting, dan
## save/load ke disk lokal (user://savegame.json). Diakses dari scene
## manapun lewat nama "GameManager".

signal coins_changed(new_amount: int)
signal high_score_changed(new_score: int)

const SAVE_PATH := "user://savegame.json"

# ---- Data yang dipersist ----
var coins: int = 0
var high_score: int = 0
var owned_skins: Array = ["default"]
var active_skin: String = "default"
var music_on: bool = true
var sound_on: bool = true
var last_daily_reward_unix: int = 0
var daily_reward_streak: int = 0
var best_combo: int = 0

# ---- State run saat ini (tidak dipersist) ----
var run_score: int = 0
var run_coins: int = 0
var run_distance: float = 0.0
var run_combo: int = 0

func _ready() -> void:
	load_game()

# ---------------- RUN LIFECYCLE ----------------

func start_new_run() -> void:
	run_score = 0
	run_coins = 0
	run_distance = 0.0
	run_combo = 0

func add_distance(delta_distance: float) -> void:
	run_distance += delta_distance
	run_score = int(run_distance)

func add_coin(amount: int = 1) -> void:
	run_coins += amount
	run_combo += 1
	if run_combo > best_combo:
		best_combo = run_combo

func break_combo() -> void:
	run_combo = 0

func end_run() -> void:
	coins += run_coins
	if run_score > high_score:
		high_score = run_score
		emit_signal("high_score_changed", high_score)
	emit_signal("coins_changed", coins)
	save_game()

func is_new_high_score() -> bool:
	return run_score >= high_score and run_score > 0

# ---------------- DIFFICULTY ----------------
## Mengembalikan nama tingkat kesulitan berdasarkan jarak (meter).
func get_difficulty_name() -> String:
	if run_distance < 500.0:
		return "Easy"
	elif run_distance < 1500.0:
		return "Normal"
	elif run_distance < 3000.0:
		return "Hard"
	else:
		return "Extreme"

## Mengembalikan multiplier kecepatan (1.0 = kecepatan dasar).
func get_speed_multiplier() -> float:
	# Naik halus mengikuti jarak, dengan batas atas supaya tetap fair.
	var mult: float = 1.0 + (run_distance / 1200.0)
	return clamp(mult, 1.0, 2.6)

## Mengembalikan jarak minimum antar rintangan (px) berdasarkan kesulitan.
func get_min_obstacle_gap() -> float:
	var mult := get_speed_multiplier()
	# Semakin cepat game, gap minimum sedikit lebih besar supaya tetap
	# adil untuk waktu reaksi pemain, tapi frekuensi tetap terasa naik
	# karena base_gap dikurangi mengikuti jarak.
	var base_gap: float = lerp(420.0, 260.0, clamp(run_distance / 3000.0, 0.0, 1.0))
	return base_gap * (mult / 1.4)

# ---------------- SHOP / SKIN ----------------

func owns_skin(skin_id: String) -> bool:
	return owned_skins.has(skin_id)

func buy_skin(skin_id: String, price: int) -> bool:
	if owns_skin(skin_id):
		return false
	if coins < price:
		return false
	coins -= price
	owned_skins.append(skin_id)
	emit_signal("coins_changed", coins)
	save_game()
	return true

func set_active_skin(skin_id: String) -> void:
	if owns_skin(skin_id):
		active_skin = skin_id
		save_game()

func spend_coins(amount: int) -> bool:
	if coins < amount:
		return false
	coins -= amount
	emit_signal("coins_changed", coins)
	save_game()
	return true

# ---------------- DAILY REWARD ----------------

const DAILY_REWARDS := [100, 150, 200, 300, 400, 500, 1000]

func can_claim_daily_reward() -> bool:
	var now := Time.get_unix_time_from_system()
	if last_daily_reward_unix == 0:
		return true
	var seconds_since: int = int(now) - last_daily_reward_unix
	return seconds_since >= 20 * 60 * 60 # >=20 jam sebagai buffer hari berganti

func claim_daily_reward() -> int:
	if not can_claim_daily_reward():
		return 0
	var now := int(Time.get_unix_time_from_system())
	var seconds_since: int = now - last_daily_reward_unix
	if last_daily_reward_unix != 0 and seconds_since <= 48 * 60 * 60:
		daily_reward_streak = (daily_reward_streak % 7) + 1
	else:
		daily_reward_streak = 1
	var reward: int = DAILY_REWARDS[daily_reward_streak - 1]
	coins += reward
	last_daily_reward_unix = now
	emit_signal("coins_changed", coins)
	save_game()
	return reward

# ---------------- SAVE / LOAD ----------------

func save_game() -> void:
	var data := {
		"coins": coins,
		"high_score": high_score,
		"owned_skins": owned_skins,
		"active_skin": active_skin,
		"music_on": music_on,
		"sound_on": sound_on,
		"last_daily_reward_unix": last_daily_reward_unix,
		"daily_reward_streak": daily_reward_streak,
		"best_combo": best_combo,
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))
		file.close()

func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return
	var text := file.get_as_text()
	file.close()
	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	coins = parsed.get("coins", 0)
	high_score = parsed.get("high_score", 0)
	owned_skins = parsed.get("owned_skins", ["default"])
	active_skin = parsed.get("active_skin", "default")
	music_on = parsed.get("music_on", true)
	sound_on = parsed.get("sound_on", true)
	last_daily_reward_unix = parsed.get("last_daily_reward_unix", 0)
	daily_reward_streak = parsed.get("daily_reward_streak", 0)
	best_combo = parsed.get("best_combo", 0)
