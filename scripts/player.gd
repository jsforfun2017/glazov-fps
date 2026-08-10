extends CharacterBody3D

const WALK_SPEED    := 6.0
const SPRINT_SPEED  := 11.0
const JUMP_VELOCITY := 5.0
const MOUSE_SENS    := 0.002
const GRAVITY       := 9.8
const SPEC_SPEED    := 20.0
const SPEC_FAST     := 60.0

@onready var camera: Camera3D        = $Head/Camera3D
@onready var head: Node3D            = $Head
@onready var col: CollisionShape3D   = $CollisionShape3D

var _pitch     := 0.0
var _spectator := false

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * MOUSE_SENS)
		var limit := PI * 0.49 if _spectator else PI * 0.45
		_pitch = clamp(_pitch - event.relative.y * MOUSE_SENS, -limit, limit)
		head.rotation.x = _pitch

	if event.is_action_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_TAB:
			_toggle_spectator()

func _toggle_spectator() -> void:
	_spectator = not _spectator
	col.disabled = _spectator
	velocity = Vector3.ZERO

func _physics_process(delta: float) -> void:
	if _spectator:
		_process_spectator(delta)
	else:
		_process_fps(delta)

func _process_fps(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var speed      := SPRINT_SPEED if Input.is_action_pressed("sprint") else WALK_SPEED
	var dir        := Vector3.ZERO
	var move_basis := global_transform.basis

	if Input.is_action_pressed("move_forward"): dir -= move_basis.z
	if Input.is_action_pressed("move_back"):    dir += move_basis.z
	if Input.is_action_pressed("move_left"):    dir -= move_basis.x
	if Input.is_action_pressed("move_right"):   dir += move_basis.x
	dir = dir.normalized()
	velocity.x = dir.x * speed
	velocity.z = dir.z * speed
	move_and_slide()

func _process_spectator(delta: float) -> void:
	var speed     := SPEC_FAST if Input.is_action_pressed("sprint") else SPEC_SPEED
	var dir       := Vector3.ZERO
	var fly_basis := head.global_transform.basis

	if Input.is_action_pressed("move_forward"): dir -= fly_basis.z
	if Input.is_action_pressed("move_back"):    dir += fly_basis.z
	if Input.is_action_pressed("move_left"):    dir -= fly_basis.x
	if Input.is_action_pressed("move_right"):   dir += fly_basis.x
	dir = dir.normalized()
	global_position += dir * speed * delta
	velocity = Vector3.ZERO
