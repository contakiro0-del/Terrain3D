# Copyright © 2025 Cory Petkovsek, Roope Palmroos, and Contributors.
# Plugin para conectar Terrain3DCustom com Terrain3D real
extends EditorPlugin

var terrain_custom_gizmo_plugin: EditorNode3DGizmoPlugin

func _enter_tree():
	# Registrar plugin de gizmos para Terrain3DCustom
	terrain_custom_gizmo_plugin = TerrainCustomGizmoPlugin.new()
	add_node_3d_gizmo_plugin(terrain_custom_gizmo_plugin)

	# Conectar sinais para detectar mudanças na cena
	scene_changed.connect(_on_scene_changed)

func _exit_tree():
	if terrain_custom_gizmo_plugin:
		remove_node_3d_gizmo_plugin(terrain_custom_gizmo_plugin)

	scene_changed.disconnect(_on_scene_changed)

func _handles(object):
	return object.get_script() != null and object.has_method("connect_to_terrain")

func _edit(object):
	if object and object.has_method("connect_to_terrain"):
		# Auto-conectar com terrenos na cena
		_auto_connect_terrain(object)

func _on_scene_changed(scene_root):
	if not scene_root:
		return

	# Encontrar todos os Terrain3DCustom e conectá-los automaticamente
	var custom_terrains = scene_root.find_children("*", "Terrain3DCustom", true, false)
	for custom_terrain in custom_terrains:
		_auto_connect_terrain(custom_terrain)

func _auto_connect_terrain(custom_terrain):
	if not custom_terrain or not custom_terrain.has_method("connect_to_terrain"):
		return

	# Se já está conectado, não fazer nada
	if custom_terrain.is_connected_to_terrain():
		return

	# Procurar por terrenos Terrain3D na cena
	var scene_root = get_tree().current_scene
	if not scene_root:
		return

	var terrain_nodes = scene_root.find_children("*", "", true, false)
	for node in terrain_nodes:
		if _is_terrain3d_node(node) and node != custom_terrain:
			var path_to_terrain = custom_terrain.get_path_to(node)
			custom_terrain.connect_to_terrain(path_to_terrain)
			print("Auto-connected ", custom_terrain.name, " to ", node.name)
			break

func _is_terrain3d_node(node):
	if not node:
		return false

	# Verificar se é um nó Terrain3D (do plugin)
	var class_name = node.get_class()
	return class_name == "Terrain3D" or \
		   node.has_method("get_terrain_position") or \
		   node.has_method("set_terrain_position")

# Plugin de Gizmos para Terrain3DCustom
class TerrainCustomGizmoPlugin extends EditorNode3DGizmoPlugin:

	func _init():
		create_material("terrain_custom_main", Color.ORANGE)
		create_handle_material("terrain_custom_handles")

	func _has_gizmo(spatial):
		return spatial.get_script() != null and spatial.has_method("connect_to_terrain")

	func _get_gizmo_name():
		return "Terrain3DCustom"

	func _redraw(gizmo):
		gizmo.clear()

		var terrain_custom = gizmo.get_node_3d()
		if not terrain_custom:
			return

		# Mostrar conexão visual se conectado
		if terrain_custom.is_connected_to_terrain():
			var connected_terrain = terrain_custom.get_connected_terrain()
			if connected_terrain:
				# Linha conectando os dois terrenos
				var lines = PackedVector3Array()
				var local_pos = terrain_custom.to_local(connected_terrain.global_position)
				lines.push_back(Vector3.ZERO)
				lines.push_back(local_pos)

				gizmo.add_lines(lines, get_material("terrain_custom_main", gizmo))

		# Handles para transformação
		var handles = PackedVector3Array()
		handles.push_back(Vector3(1, 0, 0))  # X
		handles.push_back(Vector3(0, 1, 0))  # Y
		handles.push_back(Vector3(0, 0, 1))  # Z

		var handle_ids = PackedInt32Array([0, 1, 2])
		gizmo.add_handles(handles, get_material("terrain_custom_handles", gizmo), handle_ids)

	func _get_handle_name(gizmo, handle_id, secondary):
		match handle_id:
			0: return "Move X"
			1: return "Move Y"
			2: return "Move Z"
		return ""

	func _get_handle_value(gizmo, handle_id, secondary):
		var terrain_custom = gizmo.get_node_3d()
		if terrain_custom:
			return terrain_custom.get_terrain_position()
		return Vector3.ZERO

	func _set_handle(gizmo, handle_id, secondary, camera, screen_pos):
		var terrain_custom = gizmo.get_node_3d()
		if not terrain_custom:
			return

		var current_pos = terrain_custom.get_terrain_position()
		var from = camera.project_ray_origin(screen_pos)
		var dir = camera.project_ray_normal(screen_pos)

		match handle_id:
			0: # Move X
				var plane = Plane(Vector3.FORWARD, current_pos)
				var intersection = plane.intersects_ray(from, dir)
				if intersection:
					var new_pos = Vector3(intersection.x, current_pos.y, current_pos.z)
					terrain_custom.set_terrain_position(new_pos)
			1: # Move Y
				var plane = Plane(Vector3.RIGHT, current_pos)
				var intersection = plane.intersects_ray(from, dir)
				if intersection:
					var new_pos = Vector3(current_pos.x, intersection.y, current_pos.z)
					terrain_custom.set_terrain_position(new_pos)
			2: # Move Z
				var plane = Plane(Vector3.UP, current_pos)
				var intersection = plane.intersects_ray(from, dir)
				if intersection:
					var new_pos = Vector3(current_pos.x, current_pos.y, intersection.z)
					terrain_custom.set_terrain_position(new_pos)

	func _commit_handle(gizmo, handle_id, secondary, restore, cancel):
		pass
