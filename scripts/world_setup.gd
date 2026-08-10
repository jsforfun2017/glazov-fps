extends Node3D

func _ready() -> void:
	_setup_environment()
	# Small delay so GLB finishes loading before collision gen
	await get_tree().process_frame
	await get_tree().process_frame
	_generate_collision()

func _setup_environment() -> void:
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color    = Color(0.38, 0.52, 0.72)
	sky_mat.sky_horizon_color = Color(0.68, 0.76, 0.86)
	sky_mat.sky_curve         = 0.15
	sky_mat.ground_bottom_color   = Color(0.82, 0.86, 0.90)
	sky_mat.ground_horizon_color  = Color(0.72, 0.78, 0.86)

	var sky := Sky.new()
	sky.sky_material = sky_mat

	var env := Environment.new()
	env.background_mode         = Environment.BG_SKY
	env.sky                     = sky
	env.ambient_light_source    = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy    = 0.5
	env.fog_enabled             = true
	env.fog_density             = 0.002
	env.fog_light_color         = Color(0.70, 0.75, 0.85)
	env.fog_aerial_perspective  = 0.5

	var world_env := WorldEnvironment.new()
	world_env.environment = env
	add_child(world_env)

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
		var sb  := StaticBody3D.new()
		var cs  := CollisionShape3D.new()
		cs.shape = node.mesh.create_trimesh_shape()
		sb.add_child(cs)
		node.add_child(sb)
		count += 1
	for child in node.get_children():
		count += _walk(child)
	return count
