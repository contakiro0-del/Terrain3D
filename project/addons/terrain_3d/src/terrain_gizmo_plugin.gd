# Copyright © 2025 Cory Petkovsek, Roope Palmroos, and Contributors.
# Terrain3D Gizmo Plugin for native Godot transform controls
extends EditorNode3DGizmoPlugin

func _init():
	create_material("terrain_x", Color.RED)
	create_material("terrain_y", Color.GREEN)
	create_material("terrain_z", Color.BLUE)
	create_material("terrain_center", Color.WHITE)
	create_handle_material("terrain_handles")

func _has_gizmo(spatial):
	# Verificar se é um Terrain3D e se os gizmos devem ser mostrados
	if spatial.has_method("get_terrain_position"):
		return spatial.get_meta("show_gizmos", false)
	return false

func _get_gizmo_name():
	return "Terrain3D Transform"

func _is_selectable_when_hidden():
	return false

func _redraw(gizmo):
	gizmo.clear()

	var terrain = gizmo.get_node_3d()
	if not terrain or not terrain.get_meta("show_gizmos", false):
		return

	# Criar handles para transformação
	var handles = PackedVector3Array()
	var handle_ids = PackedInt32Array()

	# Handles para translação (setas nos eixos)
	handles.push_back(Vector3(2, 0, 0))  # X
	handles.push_back(Vector3(0, 2, 0))  # Y
	handles.push_back(Vector3(0, 0, 2))  # Z
	handles.push_back(Vector3.ZERO)      # Centro

	for i in range(4):
		handle_ids.push_back(i)

	gizmo.add_handles(handles, get_material("terrain_handles", gizmo), handle_ids)

	# Criar linhas dos eixos
	var lines_x = PackedVector3Array()
	var lines_y = PackedVector3Array()
	var lines_z = PackedVector3Array()

	# Linha X (vermelha)
	lines_x.push_back(Vector3.ZERO)
	lines_x.push_back(Vector3(2, 0, 0))

	# Linha Y (verde)
	lines_y.push_back(Vector3.ZERO)
	lines_y.push_back(Vector3(0, 2, 0))

	# Linha Z (azul)
	lines_z.push_back(Vector3.ZERO)
	lines_z.push_back(Vector3(0, 0, 2))

	gizmo.add_lines(lines_x, get_material("terrain_x", gizmo))
	gizmo.add_lines(lines_y, get_material("terrain_y", gizmo))
	gizmo.add_lines(lines_z, get_material("terrain_z", gizmo))

func _get_handle_name(gizmo, handle_id, secondary):
	match handle_id:
		0: return "Move X"
		1: return "Move Y"
		2: return "Move Z"
		3: return "Move Center"
	return ""

func _get_handle_value(gizmo, handle_id, secondary):
	var terrain = gizmo.get_node_3d()
	if not terrain:
		return Vector3.ZERO

	return terrain.get_terrain_position()

func _set_handle(gizmo, handle_id, secondary, camera, screen_pos):
	var terrain = gizmo.get_node_3d()
	if not terrain:
		return

	var current_pos = terrain.get_terrain_position()
	var from = camera.project_ray_origin(screen_pos)
	var dir = camera.project_ray_normal(screen_pos)

	match handle_id:
		0: # Move X
			var plane = Plane(Vector3.FORWARD, current_pos)
			var intersection = plane.intersects_ray(from, dir)
			if intersection:
				var new_pos = Vector3(intersection.x, current_pos.y, current_pos.z)
				terrain.set_terrain_position(new_pos)
		1: # Move Y
			var plane = Plane(Vector3.RIGHT, current_pos)
			var intersection = plane.intersects_ray(from, dir)
			if intersection:
				var new_pos = Vector3(current_pos.x, intersection.y, current_pos.z)
				terrain.set_terrain_position(new_pos)
		2: # Move Z
			var plane = Plane(Vector3.UP, current_pos)
			var intersection = plane.intersects_ray(from, dir)
			if intersection:
				var new_pos = Vector3(current_pos.x, current_pos.y, intersection.z)
				terrain.set_terrain_position(new_pos)
		3: # Move Center (todos os eixos)
			var ground_plane = Plane(Vector3.UP, 0)
			var intersection = ground_plane.intersects_ray(from, dir)
			if intersection:
				var new_pos = Vector3(intersection.x, current_pos.y, intersection.z)
				terrain.set_terrain_position(new_pos)

func _commit_handle(gizmo, handle_id, secondary, restore, cancel):
	var terrain = gizmo.get_node_3d()
	if not terrain:
		return

	# Aqui você pode adicionar undo/redo se necessário
	pass
