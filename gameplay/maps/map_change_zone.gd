extends Area3D

@export var ruta_mapa: String = ""
@export var mapa_destino: PackedScene

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	if body is VehicleBody3D:
		if ruta_mapa != "":
			get_tree().change_scene_to_file(ruta_mapa)
		elif mapa_destino:
			get_tree().change_scene_to_packed(mapa_destino)
		else:
			print("ERROR: Zona de viaje sin mapa asignado.")
