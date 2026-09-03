extends Area2D
## Power-up yang melayang di jalur pemain.
## type: "magnet", "shield", "coin2x", "slowmo"

signal collected(power_type: String)

@export var power_type: String = "magnet"

var speed: float = 500.0

const COLORS := {
	"magnet": Color(0.9, 0.2, 0.9),
	"shield": Color(0.2, 0.7, 1.0),
	"coin2x": Color(1.0, 0.85, 0.1),
	"slowmo": Color(0.3, 1.0, 0.6),
}

@onready var visual: ColorRect = $Visual
@onready var label: Label = $Label

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	visual.color = COLORS.get(power_type, Color.WHITE)
	label.text = {
		"magnet": "M",
		"shield": "S",
		"coin2x": "2x",
		"slowmo": "SL",
	}.get(power_type, "?")

func _physics_process(delta: float) -> void:
	position.x -= speed * delta
	if position.x < -200:
		queue_free()

func _on_body_entered(_body: Node) -> void:
	emit_signal("collected", power_type)
	queue_free()
