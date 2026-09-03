extends Area2D
## Coin yang bisa diambil pemain. Bergerak ke kiri mengikuti world speed.
## Mendukung mode "magnet" yang membuat coin tertarik ke pemain.

signal collected(value: int)

@export var value: int = 1

var speed: float = 500.0
var magnet_target: Node2D = null
const MAGNET_SPEED := 900.0

@onready var visual: Node2D = $Visual

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	if magnet_target:
		var dir: Vector2 = (magnet_target.global_position - global_position)
		if dir.length() < 12.0:
			_collect()
			return
		position += dir.normalized() * MAGNET_SPEED * delta
	else:
		position.x -= speed * delta

	visual.rotation += delta * 4.0

	if position.x < -200:
		queue_free()

func set_magnet_target(target: Node2D) -> void:
	magnet_target = target

func _on_body_entered(_body: Node) -> void:
	_collect()

func _collect() -> void:
	emit_signal("collected", value)
	queue_free()
