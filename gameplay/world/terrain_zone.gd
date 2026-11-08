@tool
extends Area3D

@export var terrain_type: String = "tierra"

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	collision_layer = 0
	collision_mask = 0
	
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)
	
	call_deferred("registrar")

func registrar() -> void:
	TerrainManager.registrar_zona(self)

func _exit_tree() -> void:
	if not Engine.is_editor_hint():
		TerrainManager.deregistrar_zona(self)

func _on_body_entered(body: Node3D) -> void:
	_reportar_terrain(body, true)

func _on_body_exited(body: Node3D) -> void:
	_reportar_terrain(body, false)

func _on_area_entered(area: Area3D) -> void:
	if area.get_parent() is Node3D:
		_reportar_terrain(area.get_parent(), true)

func _on_area_exited(area: Area3D) -> void:
	if area.get_parent() is Node3D:
		_reportar_terrain(area.get_parent(), false)

func _reportar_terrain(body: Node3D, entrando: bool) -> void:
	if body.has_method("on_terrain_changed"):
		if entrando:
			body.on_terrain_changed(terrain_type)
		else:
			body.on_terrain_changed("desconocido")
