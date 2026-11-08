extends Node

signal vehiculo_recuperado(vehiculo_id: String)

var vehiculos_atrapados: Dictionary = {}

func _ready() -> void:
	pass

func registrar_vehiculo_atrapado(vehiculo: VehicleBody3D) -> void:
	var id = vehiculo.get_instance_id()
	vehiculos_atrapados[id] = vehiculo
	print("Vehículo registrado como atrapado: ", id)

func recuperar_a_garaje(vehiculo_id: int) -> bool:
	if not vehiculos_atrapados.has(vehiculo_id):
		return false
	
	var vehiculo = vehiculos_atrapados[vehiculo_id]
	if not vehiculo or not is_instance_valid(vehiculo):
		vehiculos_atrapados.erase(vehiculo_id)
		return false
	
	# Guardar posición actual para posible recuperación posterior
	var pos = vehiculo.global_position
	
	# Eliminar vehículo del mundo
	vehiculo.queue_free()
	vehiculos_atrapados.erase(vehiculo_id)
	
	# Añadir al almacén del garaje
	var slot_libre = _buscar_slot_libre_garaje()
	if slot_libre != -1:
		GlobalData.mover_a_almacen(slot_libre)
		print("Vehículo recuperado al garaje desde: ", pos)
		vehiculo_recuperado.emit(str(vehiculo_id))
		return true
	
	return false

func _buscar_slot_libre_garaje() -> int:
	for i in range(5):
		if not GlobalData.garaje_slots[i]["ocupado"]:
			return i
	return -1

func mostrar_menu_recuperacion() -> void:
	# Crear UI simple de recuperación
	var items = []
	for id in vehiculos_atrapados:
		if is_instance_valid(vehiculos_atrapados[id]):
			items.append(str(id))
	
	if items.is_empty():
		print("No hay vehículos atrapados")
		return
	
	print("Vehículos atrapados: ", items)
	print("Usa recuperar_a_garaje(id) para recuperar")

func intentar_autorrecate(vehiculo: VehicleBody3D) -> bool:
	# Verificar si tiene winch
	if vehiculo.has_method("tiene_addon") and vehiculo.tiene_addon(AddOnData.TipoAddOn.WINCH):
		print("Autorrescate con winch disponible")
		return true
	
	# Buscar punto de anclaje cercano
	var anclajes = get_tree().get_nodes_in_group("puntos_anclaje_winche")
	for anclaje in anclajes:
		if anclaje is Node3D:
			var dist = vehiculo.global_position.distance_to(anclaje.global_position)
			if dist < 50.0:
				print("Punto de anclaje encontrado: ", anclaje.name)
				return true
	
	return false