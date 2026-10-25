extends Node3D

const SAVE_PATH := "user://progress.cfg"
const QUESTIONS := [
	{"a": 4, "b": 5, "choices": [8, 9, 10]},
	{"a": 3, "b": 4, "choices": [6, 7, 8]},
	{"a": 2, "b": 6, "choices": [7, 8, 9]},
	{"a": 5, "b": 2, "choices": [6, 7, 8]},
	{"a": 1, "b": 8, "choices": [8, 9, 10]},
]

var answer_buttons: Array[Button] = []
var red_berry_nodes: Array[MeshInstance3D] = []
var red_leaf_nodes: Array[MeshInstance3D] = []
var gold_berry_nodes: Array[MeshInstance3D] = []
var gold_leaf_nodes: Array[MeshInstance3D] = []
var current_choices: Array = []
var question_label: Label
var feedback_label: Label
var journal_label: Label
var choices_container: HBoxContainer
var replay_button: Button
var menu_button: Button
var game_screen: Control
var home_screen: Control
var game_select_screen: Control
var badges_screen: Control
var badge_icon_label: Label
var badge_status_label: Label
var mosskip: Node3D
var idle_tween: Tween
var current_question_index := 0
var score := 0
var question_answered := false
var round_finished := false
var previous_correct_position := -1
var berry_helper_earned := false


func _ready() -> void:
	_create_world()
	_load_progress()
	_create_interface()
	_show_home()


func _create_world() -> void:
	var environment_node := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("#a9dff0")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("#d8e9dc")
	environment.ambient_light_energy = 0.8
	environment_node.environment = environment
	add_child(environment_node)

	var sunlight := DirectionalLight3D.new()
	sunlight.rotation_degrees = Vector3(-48.0, -28.0, 0.0)
	sunlight.light_energy = 1.2
	sunlight.shadow_enabled = true
	add_child(sunlight)

	var camera := Camera3D.new()
	camera.position = Vector3(0.0, 5.0, 9.0)
	camera.fov = 48.0
	add_child(camera)
	camera.look_at(Vector3(0.0, 1.1, 0.0), Vector3.UP)
	camera.current = true

	var island := MeshInstance3D.new()
	var island_mesh := CylinderMesh.new()
	island_mesh.top_radius = 6.2
	island_mesh.bottom_radius = 6.5
	island_mesh.height = 0.55
	island_mesh.radial_segments = 48
	island.mesh = island_mesh
	island.position.y = -0.28
	island.material_override = _make_material(Color("#73b77a"))
	add_child(island)

	_add_tree(Vector3(-4.2, 0.0, -1.0), Color("#5b9a64"))
	_add_tree(Vector3(4.1, 0.0, -1.4), Color("#6aa96b"))
	_add_tree(Vector3(-3.8, 0.0, 2.6), Color("#85bd72"))
	_add_house()
	_add_scene_details()
	_add_creature()
	_add_berries()


func _add_tree(tree_position: Vector3, leaf_color: Color) -> void:
	var trunk := MeshInstance3D.new()
	var trunk_mesh := CylinderMesh.new()
	trunk_mesh.top_radius = 0.18
	trunk_mesh.bottom_radius = 0.25
	trunk_mesh.height = 1.4
	trunk.mesh = trunk_mesh
	trunk.position = tree_position + Vector3(0.0, 0.7, 0.0)
	trunk.material_override = _make_material(Color("#9a694d"))
	add_child(trunk)

	var crown := MeshInstance3D.new()
	var crown_mesh := SphereMesh.new()
	crown_mesh.radius = 0.8
	crown_mesh.height = 1.5
	crown.mesh = crown_mesh
	crown.position = tree_position + Vector3(0.0, 1.75, 0.0)
	crown.scale = Vector3(1.1, 1.0, 1.0)
	crown.material_override = _make_material(leaf_color)
	add_child(crown)

	_add_sphere(
		"TreeCanopyLeft",
		tree_position + Vector3(-0.48, 1.72, 0.02),
		Vector3(0.88, 0.88, 0.86),
		_make_material(leaf_color.lightened(0.08))
	)
	_add_sphere(
		"TreeCanopyRight",
		tree_position + Vector3(0.47, 1.84, 0.03),
		Vector3(0.82, 0.9, 0.82),
		_make_material(leaf_color.darkened(0.04))
	)


func _add_house() -> void:
	var wall_material := _make_material(Color("#f2d59b"))
	var roof_material := _make_material(Color("#bd6854"))
	var roof_highlight := _make_material(Color("#d17b61"))
	var trim_material := _make_material(Color("#fff0cd"))
	var door_material := _make_material(Color("#80533f"))
	var door_detail_material := _make_material(Color("#a97855"))
	var glass_material := _make_material(Color("#9bd7e2"))
	var chimney_material := _make_material(Color("#a95649"))
	var house_center_z := -3.45
	var wall_front_z := house_center_z + 1.0

	_add_box(
		"HouseWalls",
		Vector3(0.0, 0.95, house_center_z),
		Vector3(3.2, 1.9, 2.0),
		wall_material
	)
	_add_gable(Vector3(0.0, 1.84, house_center_z + 0.015), 3.25, 1.04, 2.03, wall_material)

	var left_roof := _add_box(
		"LeftRoof",
		Vector3(-0.78, 2.36, house_center_z),
		Vector3(1.95, 0.16, 2.3),
		roof_material,
		Vector3(0.0, 0.0, 32.0)
	)
	var right_roof := _add_box(
		"RightRoof",
		Vector3(0.78, 2.36, house_center_z),
		Vector3(1.95, 0.16, 2.3),
		roof_material,
		Vector3(0.0, 0.0, -32.0)
	)
	left_roof.material_override = roof_highlight
	right_roof.material_override = roof_material

	_add_box(
		"Chimney",
		Vector3(0.9, 2.73, house_center_z - 0.32),
		Vector3(0.38, 0.9, 0.42),
		chimney_material
	)
	_add_box(
		"ChimneyCap",
		Vector3(0.9, 3.2, house_center_z - 0.32),
		Vector3(0.52, 0.12, 0.54),
		door_detail_material
	)

	for window_x in [-0.98, 0.98]:
		_add_box(
			"WindowFrame",
			Vector3(window_x, 1.2, wall_front_z + 0.05),
			Vector3(0.74, 0.72, 0.1),
			trim_material
		)
		_add_box(
			"WindowGlass",
			Vector3(window_x, 1.2, wall_front_z + 0.11),
			Vector3(0.54, 0.52, 0.04),
			glass_material
		)
		_add_box(
			"WindowVerticalBar",
			Vector3(window_x, 1.2, wall_front_z + 0.145),
			Vector3(0.045, 0.52, 0.035),
			trim_material
		)
		_add_box(
			"WindowHorizontalBar",
			Vector3(window_x, 1.2, wall_front_z + 0.145),
			Vector3(0.54, 0.045, 0.035),
			trim_material
		)

	_add_box(
		"DoorFrameLeft",
		Vector3(-0.39, 0.72, wall_front_z + 0.055),
		Vector3(0.13, 1.48, 0.12),
		trim_material
	)
	_add_box(
		"DoorFrameRight",
		Vector3(0.39, 0.72, wall_front_z + 0.055),
		Vector3(0.13, 1.48, 0.12),
		trim_material
	)
	_add_box(
		"DoorFrameTop",
		Vector3(0.0, 1.47, wall_front_z + 0.055),
		Vector3(0.9, 0.14, 0.12),
		trim_material
	)
	_add_box(
		"FrontDoor",
		Vector3(0.0, 0.67, wall_front_z + 0.12),
		Vector3(0.62, 1.3, 0.09),
		door_material
	)
	_add_box(
		"DoorPlankLeft",
		Vector3(-0.13, 0.67, wall_front_z + 0.17),
		Vector3(0.025, 1.14, 0.025),
		door_detail_material
	)
	_add_box(
		"DoorPlankRight",
		Vector3(0.13, 0.67, wall_front_z + 0.17),
		Vector3(0.025, 1.14, 0.025),
		door_detail_material
	)
	_add_sphere(
		"DoorKnob",
		Vector3(0.19, 0.67, wall_front_z + 0.21),
		Vector3(0.1, 0.1, 0.1),
		_make_material(Color("#e8b85b"))
	)

	for index in 3:
		_add_box(
			"FrontPathStone%d" % index,
			Vector3(0.0, 0.015, -2.05 + index * 0.42),
			Vector3(0.64, 0.06, 0.3),
			_make_material(Color("#c8c0a3")),
			Vector3(0.0, 0.0, 2.0 if index % 2 == 0 else -2.0)
		)


func _add_box(
	node_name: String,
	box_position: Vector3,
	box_size: Vector3,
	material: StandardMaterial3D,
	box_rotation: Vector3 = Vector3.ZERO
) -> MeshInstance3D:
	var box := MeshInstance3D.new()
	var box_mesh := BoxMesh.new()
	box_mesh.size = box_size
	box.mesh = box_mesh
	box.name = node_name
	box.position = box_position
	box.rotation_degrees = box_rotation
	box.material_override = material
	add_child(box)
	return box


func _add_gable(
	gable_position: Vector3,
	gable_width: float,
	gable_height: float,
	gable_depth: float,
	material: StandardMaterial3D
) -> void:
	var half_width := gable_width * 0.5
	var half_depth := gable_depth * 0.5
	var front_left := Vector3(-half_width, 0.0, half_depth)
	var front_right := Vector3(half_width, 0.0, half_depth)
	var front_peak := Vector3(0.0, gable_height, half_depth)
	var back_left := Vector3(-half_width, 0.0, -half_depth)
	var back_right := Vector3(half_width, 0.0, -half_depth)
	var back_peak := Vector3(0.0, gable_height, -half_depth)
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	_add_gable_triangle(surface, front_left, front_right, front_peak)
	_add_gable_triangle(surface, back_left, back_peak, back_right)
	_add_gable_triangle(surface, front_left, back_peak, back_left)
	_add_gable_triangle(surface, front_left, front_peak, back_peak)
	_add_gable_triangle(surface, front_right, back_right, back_peak)
	_add_gable_triangle(surface, front_right, back_peak, front_peak)
	_add_gable_triangle(surface, front_left, back_right, front_right)
	_add_gable_triangle(surface, front_left, back_left, back_right)

	var gable := MeshInstance3D.new()
	gable.mesh = surface.commit()
	gable.position = gable_position
	gable.material_override = material
	add_child(gable)


func _add_gable_triangle(
	surface: SurfaceTool,
	point_a: Vector3,
	point_b: Vector3,
	point_c: Vector3
) -> void:
	var normal := (point_b - point_a).cross(point_c - point_a).normalized()
	surface.set_normal(normal)
	surface.add_vertex(point_a)
	surface.add_vertex(point_b)
	surface.add_vertex(point_c)


func _add_scene_details() -> void:
	var stone_material := _make_material(Color("#b8b6a0"))
	var stone_positions := [
		Vector3(-5.0, 0.04, 0.8),
		Vector3(4.9, 0.05, 1.9),
		Vector3(3.7, 0.04, -3.2),
		Vector3(-2.8, 0.04, -3.8),
	]

	for index in stone_positions.size():
		var stone := _add_sphere(
			"IslandStone%d" % index,
			stone_positions[index],
			Vector3(0.42, 0.2, 0.32),
			stone_material
		)
		stone.rotation_degrees.y = index * 27.0

	_add_flower(Vector3(-3.2, 0.0, 1.7), Color("#f6d36b"))
	_add_flower(Vector3(3.5, 0.0, -2.2), Color("#f2a1a0"))
	_add_flower(Vector3(2.35, 0.0, -3.6), Color("#f6d36b"))


func _add_flower(flower_position: Vector3, petal_color: Color) -> void:
	var stem := MeshInstance3D.new()
	var stem_mesh := CylinderMesh.new()
	stem_mesh.top_radius = 0.025
	stem_mesh.bottom_radius = 0.035
	stem_mesh.height = 0.34
	stem.mesh = stem_mesh
	stem.position = flower_position + Vector3(0.0, 0.17, 0.0)
	stem.material_override = _make_material(Color("#4f965d"))
	add_child(stem)

	var center := flower_position + Vector3(0.0, 0.35, 0.0)
	var center_material := _make_material(Color("#f4c64e"))
	var petal_material := _make_material(petal_color)
	_add_sphere("FlowerCenter", center, Vector3(0.13, 0.13, 0.13), center_material)

	for offset in [
		Vector3(-0.1, 0.0, 0.0),
		Vector3(0.1, 0.0, 0.0),
		Vector3(0.0, 0.0, -0.1),
		Vector3(0.0, 0.0, 0.1),
		Vector3(-0.07, 0.0, -0.07),
		Vector3(0.07, 0.0, 0.07),
	]:
		_add_sphere(
			"FlowerPetal",
			center + offset,
			Vector3(0.13, 0.1, 0.11),
			petal_material
		)


func _add_creature() -> void:
	var creature := Node3D.new()
	creature.name = "Mosskip"
	add_child(creature)
	mosskip = creature

	var teal := _make_material(Color("#39ad91"))
	var cream := _make_material(Color("#ffe2a6"))
	var dark := _make_material(Color("#263d48"))
	var white := _make_material(Color("#fffaf0"))
	var pink := _make_material(Color("#ef9d9a"))
	var inner_ear := _make_material(Color("#f7b9ae"))
	var mint := _make_material(Color("#9be0bd"))

	_add_sphere_to(creature, "MosskipBody", Vector3(0.0, 0.58, 0.0), Vector3(0.98, 1.0, 0.76), teal)
	_add_sphere_to(creature, "MosskipBelly", Vector3(0.0, 0.58, 0.32), Vector3(0.58, 0.57, 0.12), cream)
	_add_sphere_to(creature, "MosskipHead", Vector3(0.0, 1.34, 0.05), Vector3(0.72, 0.68, 0.66), teal)

	var left_ear := _add_sphere_to(
		creature, "LeftEar", Vector3(-0.25, 1.62, -0.02), Vector3(0.24, 0.54, 0.2), teal
	)
	left_ear.rotation_degrees.z = 12.0
	var right_ear := _add_sphere_to(
		creature, "RightEar", Vector3(0.25, 1.62, -0.02), Vector3(0.24, 0.54, 0.2), teal
	)
	right_ear.rotation_degrees.z = -12.0
	_add_sphere_to(
		creature, "LeftInnerEar", Vector3(-0.25, 1.64, 0.055), Vector3(0.1, 0.32, 0.055), inner_ear
	)
	_add_sphere_to(
		creature, "RightInnerEar", Vector3(0.25, 1.64, 0.055), Vector3(0.1, 0.32, 0.055), inner_ear
	)

	_add_capsule_to(
		creature, "LeftLeg", Vector3(-0.29, 0.32, 0.04), 0.15, 0.58, teal
	)
	_add_capsule_to(
		creature, "RightLeg", Vector3(0.29, 0.32, 0.04), 0.15, 0.58, teal
	)
	_add_sphere_to(creature, "LeftFoot", Vector3(-0.34, 0.095, 0.16), Vector3(0.38, 0.2, 0.46), cream)
	_add_sphere_to(creature, "RightFoot", Vector3(0.34, 0.095, 0.16), Vector3(0.38, 0.2, 0.46), cream)

	_add_sphere_to(creature, "LeftEye", Vector3(-0.2, 1.4, 0.32), Vector3(0.14, 0.17, 0.1), white)
	_add_sphere_to(creature, "RightEye", Vector3(0.2, 1.4, 0.32), Vector3(0.14, 0.17, 0.1), white)
	_add_sphere_to(creature, "LeftPupil", Vector3(-0.18, 1.39, 0.365), Vector3(0.06, 0.08, 0.05), dark)
	_add_sphere_to(creature, "RightPupil", Vector3(0.22, 1.39, 0.365), Vector3(0.06, 0.08, 0.05), dark)
	_add_sphere_to(creature, "Nose", Vector3(0.0, 1.23, 0.39), Vector3(0.1, 0.07, 0.06), pink)
	_add_sphere_to(creature, "Smile", Vector3(0.0, 1.12, 0.31), Vector3(0.14, 0.035, 0.035), dark)
	_add_sphere_to(creature, "LeftCheek", Vector3(-0.29, 1.2, 0.23), Vector3(0.15, 0.1, 0.055), pink)
	_add_sphere_to(creature, "RightCheek", Vector3(0.29, 1.2, 0.23), Vector3(0.15, 0.1, 0.055), pink)
	_add_sphere_to(creature, "LeftBodySpot", Vector3(-0.36, 0.7, 0.24), Vector3(0.12, 0.1, 0.045), mint)
	_add_sphere_to(creature, "RightBodySpot", Vector3(0.36, 0.7, 0.24), Vector3(0.12, 0.1, 0.045), mint)
	_add_sphere_to(creature, "Tail", Vector3(0.0, 0.42, -0.4), Vector3(0.34, 0.32, 0.36), teal)


func _add_berries() -> void:
	var red := _make_material(Color("#e96f61"))
	var gold := _make_material(Color("#f4c64e"))
	var leaf := _make_material(Color("#4f965d"))
	for index in 8:
		var red_berry := _add_sphere(
			"RedBerry%d" % index, Vector3.ZERO, Vector3(0.18, 0.18, 0.18), red
		)
		var red_leaf := _add_sphere(
			"RedBerryLeaf%d" % index, Vector3.ZERO, Vector3(0.09, 0.035, 0.06), leaf
		)
		var gold_berry := _add_sphere(
			"GoldBerry%d" % index, Vector3.ZERO, Vector3(0.18, 0.18, 0.18), gold
		)
		var gold_leaf := _add_sphere(
			"GoldBerryLeaf%d" % index, Vector3.ZERO, Vector3(0.09, 0.035, 0.06), leaf
		)
		red_berry_nodes.append(red_berry)
		red_leaf_nodes.append(red_leaf)
		gold_berry_nodes.append(gold_berry)
		gold_leaf_nodes.append(gold_leaf)


func _update_berry_groups(red_count: int, gold_count: int) -> void:
	_position_berry_group(red_berry_nodes, red_leaf_nodes, red_count, Vector3(-2.2, 0.0, 0.82))
	_position_berry_group(gold_berry_nodes, gold_leaf_nodes, gold_count, Vector3(2.2, 0.0, 0.82))


func _position_berry_group(
	berries: Array[MeshInstance3D],
	leaves: Array[MeshInstance3D],
	count: int,
	group_center: Vector3
) -> void:
	for index in berries.size():
		var visible := index < count
		berries[index].visible = visible
		leaves[index].visible = visible
		if not visible:
			continue

		var row := floori(float(index) / 4.0)
		var column := index % 4
		var row_count := mini(4, count - row * 4)
		var horizontal_offset := (float(column) - float(row_count - 1) * 0.5) * 0.3
		var berry_position := Vector3(
			group_center.x + horizontal_offset,
			0.085,
			group_center.z + 0.22 - row * 0.42
		)
		berries[index].position = berry_position
		leaves[index].position = berry_position + Vector3(0.0, 0.08, 0.0)


func _add_sphere(
	node_name: String,
	sphere_position: Vector3,
	sphere_scale: Vector3,
	material: StandardMaterial3D
) -> MeshInstance3D:
	return _add_sphere_to(self, node_name, sphere_position, sphere_scale, material)


func _add_sphere_to(
	parent: Node3D,
	node_name: String,
	sphere_position: Vector3,
	sphere_scale: Vector3,
	material: StandardMaterial3D
) -> MeshInstance3D:
	var sphere := MeshInstance3D.new()
	var sphere_mesh := SphereMesh.new()
	sphere_mesh.radial_segments = 16
	sphere_mesh.rings = 8
	sphere.mesh = sphere_mesh
	sphere.name = node_name
	sphere.position = sphere_position
	sphere.scale = sphere_scale
	sphere.material_override = material
	parent.add_child(sphere)
	return sphere


func _add_capsule_to(
	parent: Node3D,
	node_name: String,
	capsule_position: Vector3,
	radius: float,
	height: float,
	material: StandardMaterial3D
) -> void:
	var capsule := MeshInstance3D.new()
	var capsule_mesh := CapsuleMesh.new()
	capsule_mesh.radius = radius
	capsule_mesh.height = height
	capsule.mesh = capsule_mesh
	capsule.name = node_name
	capsule.position = capsule_position
	capsule.material_override = material
	parent.add_child(capsule)


func _make_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.88
	return material


func _create_interface() -> void:
	var canvas := CanvasLayer.new()
	canvas.layer = 1
	add_child(canvas)

	var screen_root := Control.new()
	screen_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen_root.mouse_filter = Control.MOUSE_FILTER_PASS
	canvas.add_child(screen_root)

	game_screen = Control.new()
	game_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	game_screen.mouse_filter = Control.MOUSE_FILTER_PASS
	screen_root.add_child(game_screen)

	var margins := MarginContainer.new()
	margins.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margins.add_theme_constant_override("margin_left", 28)
	margins.add_theme_constant_override("margin_top", 22)
	margins.add_theme_constant_override("margin_right", 28)
	margins.add_theme_constant_override("margin_bottom", 22)
	game_screen.add_child(margins)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 14)
	margins.add_child(layout)

	var header := PanelContainer.new()
	header.add_theme_stylebox_override("panel", _make_panel_style(Color("#f7fff1")))
	layout.add_child(header)

	var header_content := VBoxContainer.new()
	header_content.add_theme_constant_override("separation", 4)
	header.add_child(header_content)

	var header_row := HBoxContainer.new()
	header_row.add_theme_constant_override("separation", 16)
	header_content.add_child(header_row)

	var title := _make_label("Mosskip", 30, Color("#244d47"))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_row.add_child(title)

	journal_label = _make_label("1 / 5    ★ 0", 17, Color("#42645a"))
	journal_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	header_row.add_child(journal_label)

	menu_button = _make_button("Menu", Color("#67947a"))
	menu_button.custom_minimum_size = Vector2(110.0, 56.0)
	menu_button.add_theme_font_size_override("font_size", 20)
	menu_button.pressed.connect(_show_home)
	header_row.add_child(menu_button)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(spacer)

	var activity_panel := PanelContainer.new()
	var activity_style := _make_panel_style(Color("#fffaf0"))
	activity_style.content_margin_top = 12.0
	activity_style.content_margin_bottom = 12.0
	activity_panel.add_theme_stylebox_override("panel", activity_style)
	activity_panel.custom_minimum_size = Vector2(0.0, 200.0)
	layout.add_child(activity_panel)

	var activity_content := VBoxContainer.new()
	activity_content.add_theme_constant_override("separation", 8)
	activity_panel.add_child(activity_content)

	question_label = _make_label("4 + 5 = ?", 46, Color("#304d45"))
	question_label.custom_minimum_size = Vector2(0.0, 64.0)
	question_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	activity_content.add_child(question_label)

	choices_container = HBoxContainer.new()
	choices_container.add_theme_constant_override("separation", 12)
	activity_content.add_child(choices_container)

	for index in 3:
		var answer_button := _make_button("", Color("#5b91c8"))
		answer_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		answer_button.pressed.connect(_on_answer_selected.bind(index))
		answer_buttons.append(answer_button)
		choices_container.add_child(answer_button)

	feedback_label = _make_label("", 20, Color("#42645a"))
	feedback_label.custom_minimum_size = Vector2(0.0, 24.0)
	feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	activity_content.add_child(feedback_label)

	replay_button = _make_button("Next", Color("#3b9a76"))
	replay_button.pressed.connect(_on_replay_pressed)
	replay_button.hide()
	activity_content.add_child(replay_button)

	_create_navigation_screens(screen_root)


func _create_navigation_screens(parent: Control) -> void:
	var home_page := _make_navigation_page(parent, 400.0)
	home_screen = home_page["screen"]
	var home_content: VBoxContainer = home_page["content"]
	var home_title := _make_label("Mosskip", 48, Color("#244d47"))
	home_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	home_content.add_child(home_title)

	var play_button := _make_button("Play", Color("#3b9a76"))
	play_button.custom_minimum_size.y = 76.0
	play_button.add_theme_font_size_override("font_size", 30)
	play_button.pressed.connect(_show_game_select)
	home_content.add_child(play_button)

	var badges_button := _make_button("Badges", Color("#d6a93e"))
	badges_button.custom_minimum_size.y = 68.0
	badges_button.add_theme_font_size_override("font_size", 26)
	badges_button.pressed.connect(_show_badges)
	home_content.add_child(badges_button)

	var games_page := _make_navigation_page(parent, 360.0)
	game_select_screen = games_page["screen"]
	var games_content: VBoxContainer = games_page["content"]
	var games_title := _make_label("Games", 40, Color("#244d47"))
	games_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	games_content.add_child(games_title)

	var berry_game_button := _make_button("Berry Maths", Color("#3b9a76"))
	berry_game_button.custom_minimum_size.y = 76.0
	berry_game_button.add_theme_font_size_override("font_size", 28)
	berry_game_button.pressed.connect(_start_game)
	games_content.add_child(berry_game_button)

	var games_back_button := _make_button("Back", Color("#67947a"))
	games_back_button.pressed.connect(_show_home)
	games_content.add_child(games_back_button)

	var badges_page := _make_navigation_page(parent, 410.0)
	badges_screen = badges_page["screen"]
	var badges_content: VBoxContainer = badges_page["content"]
	var badges_title := _make_label("Badges", 40, Color("#244d47"))
	badges_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badges_content.add_child(badges_title)

	var badge_card := PanelContainer.new()
	badge_card.add_theme_stylebox_override("panel", _make_panel_style(Color("#fff6d8")))
	badges_content.add_child(badge_card)

	var badge_row := HBoxContainer.new()
	badge_row.add_theme_constant_override("separation", 18)
	badge_card.add_child(badge_row)

	badge_icon_label = _make_label("☆", 64, Color("#9aa39a"))
	badge_icon_label.custom_minimum_size = Vector2(100.0, 88.0)
	badge_icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge_row.add_child(badge_icon_label)

	var badge_details := VBoxContainer.new()
	badge_details.add_theme_constant_override("separation", 6)
	badge_row.add_child(badge_details)

	var badge_name := _make_label("Berry helper", 24, Color("#304d45"))
	badge_details.add_child(badge_name)
	badge_status_label = _make_label("0 / 1", 20, Color("#42645a"))
	badge_details.add_child(badge_status_label)

	var badges_back_button := _make_button("Back", Color("#67947a"))
	badges_back_button.pressed.connect(_show_home)
	badges_content.add_child(badges_back_button)
	_refresh_badge_screen()


func _make_navigation_page(parent: Control, panel_height: float) -> Dictionary:
	var page := Control.new()
	page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	parent.add_child(page)

	var dimmer := ColorRect.new()
	dimmer.color = Color(0.08, 0.19, 0.22, 0.48)
	dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	page.add_child(dimmer)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	page.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(560.0, panel_height)
	panel.add_theme_stylebox_override("panel", _make_panel_style(Color("#f7fff1")))
	center.add_child(panel)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 18)
	panel.add_child(content)
	page.hide()
	return {"screen": page, "content": content}


func _show_home() -> void:
	_stop_mosskip_idle()
	game_screen.hide()
	game_select_screen.hide()
	badges_screen.hide()
	home_screen.show()


func _show_game_select() -> void:
	_stop_mosskip_idle()
	game_screen.hide()
	home_screen.hide()
	badges_screen.hide()
	game_select_screen.show()


func _show_badges() -> void:
	_stop_mosskip_idle()
	_refresh_badge_screen()
	game_screen.hide()
	home_screen.hide()
	game_select_screen.hide()
	badges_screen.show()


func _show_game() -> void:
	home_screen.hide()
	game_select_screen.hide()
	badges_screen.hide()
	game_screen.show()


func _start_game() -> void:
	current_question_index = 0
	score = 0
	previous_correct_position = -1
	round_finished = false
	_show_game()
	_show_current_question()


func _refresh_badge_screen() -> void:
	badge_icon_label.text = "★" if berry_helper_earned else "☆"
	badge_icon_label.add_theme_color_override(
		"font_color", Color("#e8b85b") if berry_helper_earned else Color("#9aa39a")
	)
	badge_status_label.text = "1 / 1" if berry_helper_earned else "0 / 1"


func _load_progress() -> void:
	var progress := ConfigFile.new()
	if progress.load(SAVE_PATH) == OK:
		berry_helper_earned = bool(progress.get_value("badges", "berry_helper", false))


func _save_progress() -> void:
	var progress := ConfigFile.new()
	progress.set_value("badges", "berry_helper", berry_helper_earned)
	progress.save(SAVE_PATH)


func _make_label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return label


func _make_button(text: String, color: Color) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0.0, 64.0)
	button.add_theme_font_size_override("font_size", 24)
	button.add_theme_color_override("font_color", Color.WHITE)
	button.add_theme_stylebox_override("normal", _make_button_style(color))
	button.add_theme_stylebox_override("hover", _make_button_style(color.lightened(0.08)))
	button.add_theme_stylebox_override("pressed", _make_button_style(color.darkened(0.12)))
	button.add_theme_stylebox_override("focus", _make_button_style(color))
	return button


func _make_button_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = 16
	style.corner_radius_top_right = 16
	style.corner_radius_bottom_left = 16
	style.corner_radius_bottom_right = 16
	style.content_margin_left = 18.0
	style.content_margin_top = 10.0
	style.content_margin_right = 18.0
	style.content_margin_bottom = 10.0
	return style


func _make_panel_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = 22
	style.corner_radius_top_right = 22
	style.corner_radius_bottom_left = 22
	style.corner_radius_bottom_right = 22
	style.content_margin_left = 22.0
	style.content_margin_top = 16.0
	style.content_margin_right = 22.0
	style.content_margin_bottom = 16.0
	return style


func _show_current_question() -> void:
	var question: Dictionary = QUESTIONS[current_question_index]
	var red_count := int(question["a"])
	var gold_count := int(question["b"])
	var answer := red_count + gold_count
	var choices: Array = question["choices"].duplicate()
	choices.erase(answer)
	choices.shuffle()
	var possible_positions := [0, 1, 2]
	if previous_correct_position < 0:
		possible_positions.erase(1)
	else:
		possible_positions.erase(previous_correct_position)
	var correct_position: int = possible_positions.pick_random()
	choices.insert(correct_position, answer)
	current_choices = choices
	previous_correct_position = correct_position
	question_label.text = "%d + %d = ?" % [red_count, gold_count]
	for index in answer_buttons.size():
		answer_buttons[index].text = str(choices[index])
		answer_buttons[index].disabled = false

	choices_container.show()
	feedback_label.text = ""
	feedback_label.add_theme_color_override("font_color", Color("#42645a"))
	replay_button.hide()
	replay_button.disabled = false
	question_answered = false
	round_finished = false
	journal_label.text = "%d / %d    ★ %d" % [
		current_question_index + 1,
		QUESTIONS.size(),
		score,
	]
	_update_berry_groups(red_count, gold_count)
	_start_mosskip_idle()


func _on_answer_selected(choice_index: int) -> void:
	if question_answered:
		return

	var question: Dictionary = QUESTIONS[current_question_index]
	var answer := int(question["a"]) + int(question["b"])
	if int(current_choices[choice_index]) == answer:
		question_answered = true
		score += 1
		feedback_label.text = "%d! Great!" % answer
		feedback_label.add_theme_color_override("font_color", Color("#26744e"))
		journal_label.text = "%d / %d    ★ %d" % [
			current_question_index + 1,
			QUESTIONS.size(),
			score,
		]
		_stop_mosskip_idle()
		for button in answer_buttons:
			button.disabled = true
		choices_container.hide()
		replay_button.text = "Next" if current_question_index < QUESTIONS.size() - 1 else "Finish"
		replay_button.disabled = true
		replay_button.show()
		_celebrate_mosskip()
	else:
		feedback_label.text = "Try again!"
		feedback_label.add_theme_color_override("font_color", Color("#8b593d"))


func _on_replay_pressed() -> void:
	if round_finished:
		current_question_index = 0
		score = 0
		previous_correct_position = -1
		_show_current_question()
	elif current_question_index < QUESTIONS.size() - 1:
		current_question_index += 1
		_show_current_question()
	else:
		round_finished = true
		feedback_label.text = "Badge!"
		feedback_label.add_theme_color_override("font_color", Color("#26744e"))
		berry_helper_earned = true
		_save_progress()
		_refresh_badge_screen()
		replay_button.text = "Again"
		journal_label.text = "%d / %d    ★ %d" % [
			QUESTIONS.size(),
			QUESTIONS.size(),
			score,
		]
		_start_mosskip_idle()


func _start_mosskip_idle() -> void:
	_stop_mosskip_idle()
	mosskip.position = Vector3.ZERO
	mosskip.rotation_degrees = Vector3.ZERO

	idle_tween = create_tween().set_loops()
	idle_tween.tween_property(
		mosskip, "rotation_degrees", Vector3(0.0, 4.0, 0.0), 0.9
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	idle_tween.parallel().tween_property(
		mosskip, "position", Vector3(0.0, 0.0, 0.025), 0.9
	)
	idle_tween.tween_property(
		mosskip, "rotation_degrees", Vector3(0.0, -4.0, 0.0), 1.8
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	idle_tween.parallel().tween_property(
		mosskip, "position", Vector3(0.0, 0.0, -0.025), 1.8
	)
	idle_tween.tween_property(
		mosskip, "rotation_degrees", Vector3.ZERO, 0.9
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	idle_tween.parallel().tween_property(mosskip, "position", Vector3.ZERO, 0.9)


func _stop_mosskip_idle() -> void:
	if idle_tween != null and idle_tween.is_running():
		idle_tween.kill()
	idle_tween = null


func _celebrate_mosskip() -> void:
	mosskip.rotation_degrees = Vector3.ZERO
	mosskip.position = Vector3.ZERO
	var hop := create_tween()
	hop.tween_property(mosskip, "position", Vector3(0.0, 0.14, 0.0), 0.18)
	hop.tween_property(mosskip, "position", Vector3.ZERO, 0.32).set_trans(Tween.TRANS_BOUNCE)
	hop.finished.connect(func() -> void: replay_button.disabled = false)
