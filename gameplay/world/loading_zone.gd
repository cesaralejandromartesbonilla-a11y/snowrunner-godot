extends Area3D

@export var cargo_data: CargoData

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	if not cargo_data:
		return
	if body.has_method("recibir_carga") and not body.tiene_carga:
		body.recibir_carga()
		print("Cargado: ", cargo_data.nombre)
