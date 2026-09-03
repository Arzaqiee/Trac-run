extends Node2D
## Menghasilkan rintangan, coin, dan power-up secara prosedural.
## Aturan fairness:
##  - Tidak pernah menumpuk 2 rintangan yang sama-sama wajib dihindari
##    dengan aksi berlawanan tanpa jarak aman (mis. LOW butuh slide,
##    TALL butuh jump, tidak akan ditaruh berdempetan).
##  - Jarak antar rintangan minimum mengikuti GameManager.get_min_obstacle_gap().
##  - Selalu ada jalur aman: minimal satu aksi (jump/slide/tidak sama sekali)
##    yang membawa pemain lewat dengan selamat.

signal powerup_collected(power_type: String)

const ObstacleScene := preload("res://scenes/Obstacle.tscn")
const CoinScene := preload("res://scenes/Coin.tscn")
const PowerUpScene := preload("res://scenes/PowerUp.tscn")

@export var spawn_x: float = 900.0
@export var ground_y: float = 0.0

var player: Node2D
var world_speed: float = 500.0
var _distance_to_next: float = 500.0
var _powerups: Array[Node] = []
var _active_coins: Array[Node] = []

# Tipe yang mudah (bisa dilewatkan hanya dengan jump biasa)
const EASY_TYPES = [0, 1] # ROCK, BOX
# Tipe yang butuh slide
const SLIDE_TYPES = [3, 5] # LASER, LOW
# Tipe lanjutan, muncul setelah jarak tertentu
const HARD_TYPES = [2, 4, 6] # PIT, TALL, MOVING

func _ready() -> void:
	randomize()

func set_player(p: Node2D) -> void:
	player = p

func _physics_process(delta: float) -> void:
	world_speed = 500.0 * GameManager.get_speed_multiplier()
	_distance_to_next -= world_speed * delta
	if _distance_to_next <= 0.0:
		_spawn_pattern()
		_distance_to_next = GameManager.get_min_obstacle_gap() + randf_range(0, 140)

func _spawn_pattern() -> void:
	var distance := GameManager.run_distance
	var pool := EASY_TYPES.duplicate()
	if distance > 300:
		pool += SLIDE_TYPES
	if distance > 900:
		pool += HARD_TYPES

	var type: int = pool[randi() % pool.size()]
	_spawn_obstacle(type)

	# Kadang tambahkan barisan coin di jalur aman (di atas, dengan arc)
	if randf() < 0.75:
		_spawn_coin_row()

	# Power-up jarang muncul, probabilitas wajar dan tidak menimpa rintangan.
	if randf() < 0.06:
		_spawn_powerup()

func _spawn_obstacle(type: int) -> void:
	var obstacle = ObstacleScene.instantiate()
	obstacle.type = type
	obstacle.speed = world_speed
	obstacle.position = Vector2(spawn_x, ground_y)
	add_child(obstacle)

func _spawn_coin_row() -> void:
	var count := randi_range(3, 6)
	var start_x := spawn_x + 120
	var arc_height := 0.0
	var is_high_row := randf() < 0.4
	for i in range(count):
		var coin = CoinScene.instantiate()
		coin.speed = world_speed
		var y_offset := 0.0
		if is_high_row:
			y_offset = -160.0
		coin.position = Vector2(start_x + i * 55, ground_y - 60 + y_offset)
		coin.collected.connect(_on_coin_collected.bind(coin))
		add_child(coin)
		_active_coins.append(coin)

func _spawn_powerup() -> void:
	var types := ["magnet", "shield", "coin2x", "slowmo"]
	var p = PowerUpScene.instantiate()
	p.power_type = types[randi() % types.size()]
	p.speed = world_speed
	p.position = Vector2(spawn_x + 200, ground_y - 120)
	p.collected.connect(func(pt): powerup_collected.emit(pt))
	add_child(p)

var coin_multiplier: int = 1

func _on_coin_collected(value: int, _coin: Node) -> void:
	GameManager.add_coin(value * coin_multiplier)

func clear_all() -> void:
	for child in get_children():
		child.queue_free()
