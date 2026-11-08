extends Node3D
class_name AddOnComponent

@export var addon_data: AddOnData
var vehiculo_padre: Node3D = null

func _ready() -> void:
	if addon_data:
		_crear_visual()

func _crear_visual() -> void:
	var mesh = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(1.5, 0.5, 2.0)
	mesh.mesh = box
	add_child(mesh)

func equipar(vehiculo: Node3D, slot_marker: Marker3D) -> void:
	vehiculo_padre = vehiculo
	
	# Sincronizar con el marker del slot
	global_transform = slot_marker.global_transform
	
	# Reparentar al vehículo
	reparent(vehiculo)
	global_transform = slot_marker.global_transform
	
	# Aplicar efectos del add-on
	if vehiculo.has_method("_aplicar_addon"):
		vehiculo._aplicar_addon(addon_data)

func desequipar() -> void:
	if vehiculo_padre and vehiculo_padre.has_method("_remover_addon"):
		vehiculo_padre._remover_addon(addon_data)
	
	# Volver a la escena principal
	var mundo = get_tree().current_scene
	reparent(mundo)