extends Node3D

var _sun: DirectionalLight3D
var _world_env: WorldEnvironment
var _sky_mat: ProceduralSkyMaterial
var _is_day := true

func _ready() -> void:
	_setup_environment()
	_setup_hud()
	await get_tree().process_frame
	await get_tree().process_frame
	_generate_collision()

func _setup_environment() -> void:
	_sun = get_parent().get_node_or_null("Sun") as DirectionalLight3D
	if _sun:
		_sun.light_energy = 1.0
		_sun.light_color  = Color(1.0, 0.96, 0.88)

	_sky_mat = ProceduralSkyMaterial.new()
	_sky_mat.sky_top_color     = Color(0.38, 0.52, 0.72)
	_sky_mat.sky_horizon_color = Color(0.68, 0.76, 0.86)
	_sky_mat.sky_curve         = 0.15
	_sky_mat.ground_bottom_color  = Color(0.82, 0.86, 0.90)
	_sky_mat.ground_horizon_color = Color(0.72, 0.78, 0.86)

	var sky := Sky.new()
	sky.sky_material = _sky_mat

	var env := Environment.new()
	env.background_mode        = Environment.BG_SKY
	env.sky                    = sky
	env.ambient_light_source   = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy   = 0.15
	env.tonemap_mode           = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure       = 0.9
	env.fog_enabled            = true
	env.fog_density            = 0.002
	env.fog_light_color        = Color(0.70, 0.75, 0.85)
	env.fog_aerial_perspective = 0.5

	_world_env = WorldEnvironment.new()
	_world_env.environment = env
	add_child(_world_env)

func _setup_hud() -> void:
	var cv  := CanvasLayer.new()

	# Controls hint (top-left)
	var lbl := Label.new()
	lbl.text = "WASD — move   |   Mouse — look   |   Shift — sprint   |   Space — jump   |   F — spectator / soul mode   |   Esc — free cursor"
	lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.65))
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.position = Vector2(12, 8)
	cv.add_child(lbl)

	# Day/Night button (top-right)
	var btn := Button.new()
	btn.text = "🌙  Night"
	btn.add_theme_font_size_override("font_size", 14)
	btn.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	btn.position = Vector2(-130, 6)
	btn.size = Vector2(118, 32)
	btn.pressed.connect(_on_day_night_pressed.bind(btn))
	cv.add_child(btn)

	add_child(cv)

func _on_day_night_pressed(btn: Button) -> void:
	_is_day = not _is_day
	_sun = get_parent().get_node_or_null("Sun") as DirectionalLight3D

	if _is_day:
		btn.text = "🌙  Night"
		if _sun:
			_sun.light_energy = 1.0
			_sun.light_color  = Color(1.0, 0.96, 0.88)
		_sky_mat.sky_top_color     = Color(0.38, 0.52, 0.72)
		_sky_mat.sky_horizon_color = Color(0.68, 0.76, 0.86)
		_sky_mat.ground_bottom_color  = Color(0.82, 0.86, 0.90)
		_sky_mat.ground_horizon_color = Color(0.72, 0.78, 0.86)
		_world_env.environment.fog_light_color = Color(0.70, 0.75, 0.85)
		_world_env.environment.ambient_light_energy = 0.15
	else:
		btn.text = "☀️  Day"
		if _sun:
			_sun.light_energy = 0.18
			_sun.light_color  = Color(0.72, 0.80, 1.0)
		_sky_mat.sky_top_color     = Color(0.01, 0.01, 0.06)
		_sky_mat.sky_horizon_color = Color(0.04, 0.05, 0.12)
		_sky_mat.ground_bottom_color  = Color(0.02, 0.02, 0.04)
		_sky_mat.ground_horizon_color = Color(0.03, 0.03, 0.08)
		_world_env.environment.fog_light_color = Color(0.10, 0.12, 0.22)
		_world_env.environment.ambient_light_energy = 0.08

func _generate_collision() -> void:
	var city := get_node_or_null("GlazovCity")
	if not city:
		push_warning("GlazovCity node not found — skipping collision gen")
		return
	var generated := _walk(city)
	print("Collision generated for %d mesh(es)" % generated)

func _walk(node: Node) -> int:
	var count := 0
	if node is MeshInstance3D and node.mesh != null:
		var sb := StaticBody3D.new()
		var cs := CollisionShape3D.new()
		cs.shape = node.mesh.create_trimesh_shape()
		sb.add_child(cs)
		node.add_child(sb)
		count += 1
	for child in node.get_children():
		count += _walk(child)
	return count
