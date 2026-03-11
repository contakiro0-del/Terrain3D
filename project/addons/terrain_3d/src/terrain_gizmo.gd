# Copyright © 2025 Cory Petkovsek, Roope Palmroos, and Contributors.
# Terrain Transform Gizmo System
extends Node3D

signal terrain_transformed(transform_type: String, delta: Vector3)

enum GizmoMode {
	TRANSLATE,
	ROTATE,
	SCALE
}

var terrain: Terrain3D
var plugin: EditorPlugin
var current_mode: GizmoMode = GizmoMode.TRANSLATE
var is_visible: bool = false
var gizmo_meshes: Array[MeshInstance3D] = []
var gizmo_materials: Array[StandardMaterial3D] = []

# Cores dos gizmos (igual ao Godot)
const COLOR_X = Color.RED
const COLOR_Y = Color.GREEN
const COLOR_Z = Color.BLUE
const COLOR_CENTER = Color.WHITE

# Tamanhos dos gizmos
const ARROW_LENGTH = 2.0
const ARROW_RADIUS = 0.05
const ARROW_HEAD_LENGTH = 0.3
const ARROW_HEAD_RADIUS = 0.15
const CENTER_SPHERE_RADIUS = 0.2

func _ready():
	_create_gizmo_meshes()
	set_visible(false)

func initialize(p_terrain: Terrain3D, p_plugin: EditorPlugin):
	terrain = p_terrain
	plugin = p_plugin

	# Posicionar gizmo no centro do terreno
	if terrain:
		global_position = terrain.global_position

func set_gizmo_mode(mode: GizmoMode):
	current_mode = mode
	_update_gizmo_display()

func set_visible(visible: bool):
	is_visible = visible
	for mesh in gizmo_meshes:
		mesh.visible = visible

func _create_gizmo_meshes():
	_clear_gizmos()

	match current_mode:
		GizmoMode.TRANSLATE:
			_create_translate_gizmos()
		GizmoMode.ROTATE:
			_create_rotate_gizmos()
		GizmoMode.SCALE:
			_create_scale_gizmos()

func _clear_gizmos():
	for mesh in gizmo_meshes:
		if is_instance_valid(mesh):
			mesh.queue_free()
	gizmo_meshes.clear()
	gizmo_materials.clear()

func _create_translate_gizmos():
	# Seta X (Vermelha)
	var arrow_x = _create_arrow_mesh(Vector3.RIGHT, COLOR_X)
	arrow_x.position = Vector3.ZERO
	arrow_x.rotation_degrees = Vector3(0, 0, -90)
	add_child(arrow_x)
	gizmo_meshes.append(arrow_x)

	# Seta Y (Verde)
	var arrow_y = _create_arrow_mesh(Vector3.UP, COLOR_Y)
	arrow_y.position = Vector3.ZERO
	add_child(arrow_y)
	gizmo_meshes.append(arrow_y)

	# Seta Z (Azul)
	var arrow_z = _create_arrow_mesh(Vector3.FORWARD, COLOR_Z)
	arrow_z.position = Vector3.ZERO
	arrow_z.rotation_degrees = Vector3(90, 0, 0)
	add_child(arrow_z)
	gizmo_meshes.append(arrow_z)

	# Centro (Esfera branca)
	var center = _create_sphere_mesh(COLOR_CENTER)
	add_child(center)
	gizmo_meshes.append(center)

func _create_rotate_gizmos():
	# Círculo X (Vermelho)
	var circle_x = _create_circle_mesh(COLOR_X)
	circle_x.rotation_degrees = Vector3(0, 0, 90)
	add_child(circle_x)
	gizmo_meshes.append(circle_x)

	# Círculo Y (Verde)
	var circle_y = _create_circle_mesh(COLOR_Y)
	add_child(circle_y)
	gizmo_meshes.append(circle_y)

	# Círculo Z (Azul)
	var circle_z = _create_circle_mesh(COLOR_Z)
	circle_z.rotation_degrees = Vector3(90, 0, 0)
	add_child(circle_z)
	gizmo_meshes.append(circle_z)

func _create_scale_gizmos():
	# Cubo X (Vermelho)
	var cube_x = _create_cube_mesh(COLOR_X)
	cube_x.position = Vector3(ARROW_LENGTH, 0, 0)
	add_child(cube_x)
	gizmo_meshes.append(cube_x)

	# Cubo Y (Verde)
	var cube_y = _create_cube_mesh(COLOR_Y)
	cube_y.position = Vector3(0, ARROW_LENGTH, 0)
	add_child(cube_y)
	gizmo_meshes.append(cube_y)

	# Cubo Z (Azul)
	var cube_z = _create_cube_mesh(COLOR_Z)
	cube_z.position = Vector3(0, 0, ARROW_LENGTH)
	add_child(cube_z)
	gizmo_meshes.append(cube_z)

	# Linhas conectoras
	_create_connector_lines()

func _create_arrow_mesh(direction: Vector3, color: Color) -> MeshInstance3D:
	var mesh_instance = MeshInstance3D.new()

	# Criar mesh da seta (cilindro + cone)
	var array_mesh = ArrayMesh.new()

	# Haste da seta (cilindro)
	var cylinder = CylinderMesh.new()
	cylinder.height = ARROW_LENGTH
	cylinder.top_radius = ARROW_RADIUS
	cylinder.bottom_radius = ARROW_RADIUS

	# Cabeça da seta (cone)
	var cone = CylinderMesh.new()
	cone.height = ARROW_HEAD_LENGTH
	cone.top_radius = 0.0
	cone.bottom_radius = ARROW_HEAD_RADIUS

	# Combinar meshes
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, cylinder.surface_get_arrays(0))

	mesh_instance.mesh = array_mesh

	# Material
	var material = StandardMaterial3D.new()
	material.albedo_color = color
	material.flags_unshaded = true
	material.no_depth_test = true
	mesh_instance.material_override = material
	gizmo_materials.append(material)

	return mesh_instance

func _create_sphere_mesh(color: Color) -> MeshInstance3D:
	var mesh_instance = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = CENTER_SPHERE_RADIUS
	sphere.height = CENTER_SPHERE_RADIUS * 2
	mesh_instance.mesh = sphere

	var material = StandardMaterial3D.new()
	material.albedo_color = color
	material.flags_unshaded = true
	material.no_depth_test = true
	mesh_instance.material_override = material
	gizmo_materials.append(material)

	return mesh_instance

func _create_circle_mesh(color: Color) -> MeshInstance3D:
	var mesh_instance = MeshInstance3D.new()

	# Criar círculo usando ArrayMesh
	var array_mesh = ArrayMesh.new()
	var vertices = PackedVector3Array()
	var indices = PackedInt32Array()

	var segments = 64
	var radius = ARROW_LENGTH

	for i in range(segments):
		var angle = i * 2.0 * PI / segments
		vertices.append(Vector3(cos(angle) * radius, 0, sin(angle) * radius))

		if i < segments - 1:
			indices.append(i)
			indices.append(i + 1)
		else:
			indices.append(i)
			indices.append(0)

	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_INDEX] = indices

	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_LINES, arrays)
	mesh_instance.mesh = array_mesh

	var material = StandardMaterial3D.new()
	material.albedo_color = color
	material.flags_unshaded = true
	material.no_depth_test = true
	mesh_instance.material_override = material
	gizmo_materials.append(material)

	return mesh_instance

func _create_cube_mesh(color: Color) -> MeshInstance3D:
	var mesh_instance = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(0.2, 0.2, 0.2)
	mesh_instance.mesh = box

	var material = StandardMaterial3D.new()
	material.albedo_color = color
	material.flags_unshaded = true
	material.no_depth_test = true
	mesh_instance.material_override = material
	gizmo_materials.append(material)

	return mesh_instance

func _create_connector_lines():
	# Linhas conectando o centro aos cubos de escala
	var line_material = StandardMaterial3D.new()
	line_material.albedo_color = Color.GRAY
	line_material.flags_unshaded = true
	line_material.no_depth_test = true

	# Linha X
	var line_x = _create_line_mesh(Vector3.ZERO, Vector3(ARROW_LENGTH, 0, 0))
	line_x.material_override = line_material
	add_child(line_x)
	gizmo_meshes.append(line_x)

	# Linha Y
	var line_y = _create_line_mesh(Vector3.ZERO, Vector3(0, ARROW_LENGTH, 0))
	line_y.material_override = line_material
	add_child(line_y)
	gizmo_meshes.append(line_y)

	# Linha Z
	var line_z = _create_line_mesh(Vector3.ZERO, Vector3(0, 0, ARROW_LENGTH))
	line_z.material_override = line_material
	add_child(line_z)
	gizmo_meshes.append(line_z)

func _create_line_mesh(from: Vector3, to: Vector3) -> MeshInstance3D:
	var mesh_instance = MeshInstance3D.new()
	var array_mesh = ArrayMesh.new()

	var vertices = PackedVector3Array([from, to])
	var indices = PackedInt32Array([0, 1])

	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_INDEX] = indices

	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_LINES, arrays)
	mesh_instance.mesh = array_mesh

	return mesh_instance

func _update_gizmo_display():
	_create_gizmo_meshes()
	set_visible(is_visible)

func _input(event):
	if not is_visible or not terrain:
		return

	# Detectar mudança de modo com teclas
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_G: # Translate (Grab)
				set_gizmo_mode(GizmoMode.TRANSLATE)
			KEY_R: # Rotate
				set_gizmo_mode(GizmoMode.ROTATE)
			KEY_S: # Scale
				set_gizmo_mode(GizmoMode.SCALE)
