extends Node3D

signal carga_recibida(nombre_carga: String)
signal carga_entregada(nombre_carga: String, dinero_ganado: int)

@export var contenido: CargoData

func _ready() -> void:
	add_to_group("cargas")
	_actualizar_visual()

func _actualizar_visual() -> void:
	if not contenido:
		return
	var box = MeshInstance3D.new()
	box.mesh = BoxMesh.new()
	box.mesh.size = Vector3(1.0, 0.8, 1.0)
	add_child(box)

func recoger() -> CargoData:
	var data = contenido
	contenido = null
	queue_free()
	return data
