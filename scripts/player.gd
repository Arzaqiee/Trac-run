extends CharacterBody2D
## Kontrol pemain: tap = lompat, double tap = double jump,
## swipe ke bawah = slide. Karakter berlari otomatis (auto-run),
## posisi X tetap, dunia yang bergerak (lihat spawner.gd / game.gd).

signal died

const JUMP_VELOCITY := -1000.0
const DOUBLE_JUMP_VELOCITY := -850.0
const GRAVITY := 2600.0
const SLIDE_DURATION := 0.6
const SWIPE_MIN_DISTANCE := 60.0
const DOUBLE_TAP_WINDOW := 0.30

const STAND_HEIGHT := 90.0
const SLIDE_HEIGHT := 46.0

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var body_visual: ColorRect = $BodyVisual
@onready var shield_visual: Node2D = $ShieldVisual

var is_alive := true
var is_sliding := false
var jumps_used := 0
var max_jumps := 2

var has_shield := false

var _touch_start_pos := Vector2.ZERO
var _touch_start_time := 0.0
var _last_tap_time := -10.0
var _slide_timer := 0.0

func _ready() -> void:
	shield_visual.visible = false
	_set_stand_shape()

func _physics_process(delta: float) -> void:
	if not is_alive:
		return

	# Gravitasi
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	else:
		if velocity.y > 0:
			velocity.y = 0
		jumps_used = 0

	# Timer slide
	if is_sliding:
		_slide_timer -= delta
		if _slide_timer <= 0.0:
			end_slide()

	move_and_slide()

func _unhandled_input(event: InputEvent) -> void:
	if not is_alive:
		return

	if event is InputEventScreenTouch:
		if event.pressed:
			_touch_start_pos = event.position
			_touch_start_time = Time.get_ticks_msec() / 1000.0
		else:
			var dt := (Time.get_ticks_msec() / 1000.0) - _touch_start_time
			var dy: float = event.position.y - _touch_start_pos.y
			var dx: float = event.position.x - _touch_start_pos.x
			if dy > SWIPE_MIN_DISTANCE and abs(dy) > abs(dx):
				start_slide()
			elif dt < 0.35:
				_handle_tap()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# Dukungan mouse untuk testing di desktop/editor.
		_handle_tap()
	elif event is InputEventKey and event.pressed:
		if event.keycode == KEY_DOWN or event.keycode == KEY_S:
			start_slide()
		elif event.keycode == KEY_SPACE or event.keycode == KEY_UP:
			_handle_tap()

func _handle_tap() -> void:
	var now := Time.get_ticks_msec() / 1000.0
	_last_tap_time = now
	jump()

func jump() -> void:
	if is_sliding:
		end_slide()
	if is_on_floor():
		velocity.y = JUMP_VELOCITY
		jumps_used = 1
		_play_anim_jump()
	elif jumps_used < max_jumps:
		velocity.y = DOUBLE_JUMP_VELOCITY
		jumps_used += 1
		_play_anim_jump()

func start_slide() -> void:
	if not is_on_floor() or is_sliding:
		return
	is_sliding = true
	_slide_timer = SLIDE_DURATION
	_set_slide_shape()

func end_slide() -> void:
	is_sliding = false
	_set_stand_shape()

func _set_stand_shape() -> void:
	var shape := collision_shape.shape as RectangleShape2D
	if shape:
		shape.size = Vector2(60, STAND_HEIGHT)
	collision_shape.position = Vector2(0, -STAND_HEIGHT / 2.0)
	body_visual.size = Vector2(60, STAND_HEIGHT)
	body_visual.position = Vector2(-30, -STAND_HEIGHT)

func _set_slide_shape() -> void:
	var shape := collision_shape.shape as RectangleShape2D
	if shape:
		shape.size = Vector2(60, SLIDE_HEIGHT)
	collision_shape.position = Vector2(0, -SLIDE_HEIGHT / 2.0)
	body_visual.size = Vector2(60, SLIDE_HEIGHT)
	body_visual.position = Vector2(-30, -SLIDE_HEIGHT)

func _play_anim_jump() -> void:
	var tw := create_tween()
	tw.tween_property(body_visual, "scale", Vector2(0.85, 1.15), 0.08)
	tw.tween_property(body_visual, "scale", Vector2(1, 1), 0.15)

func activate_shield() -> void:
	has_shield = true
	shield_visual.visible = true

func die() -> void:
	if has_shield:
		has_shield = false
		shield_visual.visible = false
		return
	if not is_alive:
		return
	is_alive = false
	emit_signal("died")
	var tw := create_tween()
	tw.tween_property(body_visual, "rotation_degrees", 90, 0.3)
	tw.tween_property(body_visual, "modulate:a", 0.5, 0.3)
