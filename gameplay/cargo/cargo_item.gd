extends RigidBody3D

@export var cargo_data: CargoData
@export var peso_real: float = 500.0
var puede_acoplar_carga: bool = true
var slot_actual: Marker3D = null

func _ready() -> void:
	mass = peso_real
	freeze = false
	sleeping = false
	collision_layer = 1
	collision_mask = 1
	add_to_group("carga_suelta")

func acoplar_carga(slot: Marker3D) -> void:
	if not puede_acoplar_carga:
		return
	
	slot_actual = slot
	puede_acoplar_carga = false
	
	# Desactivar físicas
	freeze = true
	collision_layer = 0
	collision_mask = 0
	
	# Cambiar de padre al vehículo/remolque
	var vehiculo = slot.get_parent()
	while vehiculo and not vehiculo.is_in_group("jugador") and not vehiculo.is_in_group("remolques"):
		vehiculo = vehiculo.get_parent()
	
	if vehiculo:
		reparent(vehiculo)
		global_transform = slot.global_transform
		
		# Sincronizar con PhysicsServer
		PhysicsServer3D.body_set_state(get_rid(), PhysicsServer3D.BODY_STATE_TRANSFORM, global_transform)
		
		# Notificar al vehículo
		if vehiculo.has_method("_on_carga_acoplada"):
			vehiculo._on_carga_acoplada(cargo_data, slot)
	
	print("Carga acoplada: ", cargo_data.nombre, " en slot: ", slot.name)

func desacoplar_carga() -> void:
	if not slot_actual:
		return
	
	var vehiculo = get_parent()
	
	# Volver a la escena principal
	var mundo = get_tree().current_scene
	reparent(mundo)
	
	# Liberar slot
	slot_actual.set_meta("ocupado", false)
	slot_actual = null
	
	# Restaurar físicas
	collision_layer = 1
	collision_mask = 1
	freeze = false
	sleeping = false
	mass = peso_real
	
	# Impulsar hacia afuera
	await get_tree().physics_frame
	var impulso = (global_transform.basis.z * 2.0) + (Vector3.UP * 3.0)
	apply_central_impulse(impulso)
	
	puede_acoplar_carga = true
	await get_tree().create_timer(1.5).timeout
	
	# Notificar al vehículo
	if vehiculo and vehiculo.has_method("_on_carga_desacoplada"):
		vehiculo._on_carga_desacoplada(cargo_data)

func _on_body_entered(body: Node3D) -> void:
	if body.has_method("acoplar_carga") and (body.get("puede_acoplar_carga") ?? true):
		var slot = _buscar_slot_en_vehiculo(body)
		if slot:
			body.acoplar_carga(slot)

func _buscar_slot_en_vehiculo(vehiculo: Node3D) -> Marker3D:
	if vehiculo.has_method("get_slot_libre"):
		return vehiculo.get_slot_libre()
	return null