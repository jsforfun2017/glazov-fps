extends Node3D

var _sun: DirectionalLight3D
var _world_env: WorldEnvironment
var _sky_mat: ProceduralSkyMaterial
var _is_day := true

const CITY_COLORS := {
	# Apartments / buildings
	"soviet": Color(0.82, 0.76, 0.60), "apart2": Color(0.62, 0.75, 0.58),
	"cream": Color(0.88, 0.80, 0.52), "white": Color(0.96, 0.94, 0.90),
	"gray":  Color(0.55, 0.55, 0.58), "conc":  Color(0.50, 0.48, 0.46),
	"roof":  Color(0.20, 0.18, 0.16),
	# Windows / glass
	"win":   Color(0.18, 0.32, 0.55), "blue":  Color(0.12, 0.20, 0.68),
	# Roads / ground
	"road":  Color(0.14, 0.14, 0.15), "road2": Color(0.16, 0.16, 0.17),
	"swlk":  Color(0.58, 0.56, 0.52), "pavement2": Color(0.55, 0.53, 0.50),
	"stripe": Color(0.85, 0.78, 0.12), "dirt":  Color(0.35, 0.25, 0.15),
	# Nature
	"green": Color(0.20, 0.48, 0.12), "pine_gr2": Color(0.12, 0.32, 0.08),
	"pine_bark2": Color(0.20, 0.13, 0.07),
	# Street furniture
	"lamp2": Color(0.62, 0.60, 0.50), "bench2": Color(0.30, 0.20, 0.10),
	"kiosk": Color(0.72, 0.50, 0.22), "metal": Color(0.28, 0.28, 0.30),
	# Vehicles
	"car_gray": Color(0.38, 0.38, 0.40), "car_gray2": Color(0.42, 0.42, 0.44),
	"car_blue": Color(0.12, 0.22, 0.65), "car_red":  Color(0.68, 0.08, 0.06),
	"car_white": Color(0.88, 0.88, 0.88),
	# Special buildings
	"hosp": Color(0.95, 0.95, 0.92), "red": Color(0.82, 0.04, 0.04),
	"chimney": Color(0.28, 0.24, 0.20),
	"mil_green": Color(0.32, 0.40, 0.24), "mil_gray": Color(0.42, 0.42, 0.40),
	# Market / shops
	"market_wall": Color(0.82, 0.72, 0.52), "market_roof": Color(0.42, 0.22, 0.12),
	"stall_top": Color(0.78, 0.40, 0.10), "shed_col": Color(0.48, 0.44, 0.38),
	"shop_yel": Color(0.85, 0.72, 0.20),
	# Lenin plaza / monument
	"plaza_tile": Color(0.68, 0.66, 0.62), "obelisk": Color(0.48, 0.48, 0.52),
	"monument_b": Color(0.42, 0.40, 0.38),
	"cult_wall": Color(0.72, 0.65, 0.52), "cult_col": Color(0.85, 0.82, 0.75),
	"cult_roof": Color(0.22, 0.18, 0.15),
	"flagpole": Color(0.55, 0.55, 0.58), "flag_r": Color(0.82, 0.04, 0.04),
	"star_r": Color(0.88, 0.05, 0.05), "gold": Color(0.88, 0.68, 0.05),
	# Canal / water / tram
	"canal_bed": Color(0.28, 0.38, 0.30), "water": Color(0.10, 0.28, 0.55),
	"water2": Color(0.12, 0.32, 0.58), "bridge_c": Color(0.48, 0.44, 0.38),
	"tram_roof": Color(0.72, 0.12, 0.08), "tram_wall": Color(0.92, 0.92, 0.95),
	# Graveyard
	"grave_dirt": Color(0.08, 0.06, 0.05), "grave_stone": Color(0.20, 0.20, 0.22),
	"grave_iron": Color(0.07, 0.07, 0.08), "grave_chapel": Color(0.28, 0.26, 0.24),
	"grave_roof2": Color(0.06, 0.05, 0.05), "dead_bark": Color(0.10, 0.08, 0.06),
	"grave_path": Color(0.18, 0.16, 0.14), "crypt_stone": Color(0.24, 0.22, 0.20),
}

func _ready() -> void:
	_setup_environment()
	_setup_hud()
	await get_tree().process_frame
	await get_tree().process_frame
	_apply_city_colors()
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
	# Glow
	env.glow_enabled           = true
	env.glow_normalized        = false
	env.glow_intensity         = 0.5
	env.glow_strength          = 1.2
	env.glow_bloom             = 0.08
	env.glow_blend_mode        = Environment.GLOW_BLEND_MODE_SOFTLIGHT
	env.glow_hdr_threshold     = 0.7
	env.glow_hdr_scale         = 2.0
	# Color grading — Soviet desaturated, high contrast look
	env.adjustment_enabled     = true
	env.adjustment_brightness  = 1.02
	env.adjustment_contrast    = 1.15
	env.adjustment_saturation  = 0.72

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

	# Vignette overlay
	var vig := ColorRect.new()
	vig.set_anchors_preset(Control.PRESET_FULL_RECT)
	vig.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var vig_mat := ShaderMaterial.new()
	var vig_shader := Shader.new()
	vig_shader.code = "shader_type canvas_item;\nvoid fragment() {\nvec2 uv = UV - 0.5;\nfloat v = 1.0 - dot(uv * 1.8, uv * 1.8);\nv = pow(clamp(v, 0.0, 1.0), 1.3);\nCOLOR = vec4(0.0, 0.0, 0.0, 0.60 * (1.0 - v));\n}"
	vig_mat.shader = vig_shader
	vig.material = vig_mat
	cv.add_child(vig)

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

func _apply_city_colors() -> void:
	var city := get_node_or_null("GlazovCity")
	if not city:
		push_warning("GlazovCity not found for color pass")
		return
	var hits := _recolor_mesh(city)
	print("City colors applied: %d surfaces recolored" % hits)

func _recolor_mesh(node: Node) -> int:
	var hits := 0
	if node is MeshInstance3D and node.mesh != null:
		var mesh := node.mesh as Mesh
		for i in range(mesh.get_surface_count()):
			var mat := mesh.surface_get_material(i)
			if mat == null:
				continue
			var mat_name := mat.resource_name
			if CITY_COLORS.has(mat_name):
				var sm := StandardMaterial3D.new()
				sm.albedo_color = CITY_COLORS[mat_name]
				sm.roughness = 0.85
				node.set_surface_override_material(i, sm)
				hits += 1
	for child in node.get_children():
		hits += _recolor_mesh(child)
	return hits

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
