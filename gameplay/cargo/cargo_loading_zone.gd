extends Area3D

@export var slots: Array[Marker3D] = []

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	
	if slots.is_empty():
		var nodos_slots = get_node_or_null("Slots")
		if nodos_slots:
			for hijo in nodos_slots.get_children():
				if hijo is Marker3D:
					slots.append(hijo)

func _on_body_entered(body: Node3D) -> void:
	if body.has_method("acoplar_carga") and (body.get("puede_acoplar_carga") if body.has("puede_acoplar_carga") else true):
		var slot_libre = _buscar_slot_libre()
		if slot_libre:
			slot_libre.set_meta("ocupado", true)
			body.acoplar_carga(slot_libre)
			
			if not body.tree_exited.is_connected(func(): slot_libre.set_meta("ocupado", false)):
				body.tree_exited.connect(func(): slot_libre.set_meta("ocupado", false))
		else:
			print("Zona de carga llena")

func _buscar_slot_libre() -> Marker3D:
	for s in slots:
		if not s.has_meta("ocupado") or s.get_meta("ocupado") == false:
			return s
	return null

func liberar_todos_los_slots() -> void:
	for s in slots:
		s.set_meta("ocupado", false)
