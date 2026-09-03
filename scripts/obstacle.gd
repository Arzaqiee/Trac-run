extends Area2D
## Rintangan generik. Tipe menentukan bentuk, posisi collision, dan warna.
## Semua rintangan bergerak ke kiri mengikuti world_speed dari spawner.

enum ObstacleType { ROCK, BOX, PIT, LASER, TALL, LOW, MOVING }

@export var type: ObstacleType = ObstacleType.ROCK

@onready var visual: ColorRect = $Visual
@onready var shape: CollisionShape2D = $CollisionShape2D

var speed: float = 500.0
var _move_time := 0.0
var _base_y := 0.0

const COLORS := {
	ObstacleType.ROCK: Color(0.45, 0.42, 0.4),
	ObstacleType.BOX: Color(0.6, 0.42, 0.2),
	ObstacleType.PIT: Color(0.05, 0.05, 0.08),
	ObstacleType.LASER: Color(1.0, 0.2, 0.2),
	ObstacleType.TALL: Color(0.35, 0.3, 0.55),
	ObstacleType.LOW: Color(0.9, 0.6, 0.1),
	ObstacleType.MOVING: Color(0.8, 0.15, 0.6),
}

func _ready() -> void:
	_configure_for_type()
	body_entered.connect(_on_body_entered)
	_base_y = position.y

func _configure_for_type() -> void:
	var rect_shape := RectangleShape2D.new()
	match type:
		ObstacleType.ROCK:
			rect_shape.size = Vector2(60, 70)
			visual.size = rect_shape.size
			visual.position = -rect_shape.size / 2.0
		ObstacleType.BOX:
			rect_shape.size = Vector2(64, 64)
			visual.size = rect_shape.size
			visual.position = -rect_shape.size / 2.0
		ObstacleType.PIT:
			rect_shape.size = Vector2(120, 20)
			visual.size = rect_shape.size
			visual.position = -rect_shape.size / 2.0
		ObstacleType.LASER:
			# Melayang di ketinggian kepala; harus slide untuk lewat.
			rect_shape.size = Vector2(90, 24)
			visual.size = rect_shape.size
			visual.position = -rect_shape.size / 2.0
			position.y -= 70
		ObstacleType.TALL:
			rect_shape.size = Vector2(60, 130)
			visual.size = rect_shape.size
			visual.position = -rect_shape.size / 2.0
		ObstacleType.LOW:
			# Rintangan rendah di tanah; harus slide untuk lewat.
			rect_shape.size = Vector2(70, 40)
			visual.size = rect_shape.size
			visual.position = -rect_shape.size / 2.0
			position.y -= 10
		ObstacleType.MOVING:
			rect_shape.size = Vector2(56, 56)
			visual.size = rect_shape.size
			visual.position = -rect_shape.size / 2.0
	shape.shape = rect_shape
	visual.color = COLORS[type]

func _physics_process(delta: float) -> void:
	position.x -= speed * delta
	if type == ObstacleType.MOVING:
		_move_time += delta
		position.y = _base_y + sin(_move_time * 3.0) * 55.0
	if position.x < -200:
		queue_free()

func _on_body_entered(body: Node) -> void:
	if body.has_method("die"):
		if type == ObstacleType.PIT:
			# Pit hanya berbahaya jika pemain tidak melompat (di lantai).
			if body.is_on_floor():
				body.die()
		else:
			body.die()
