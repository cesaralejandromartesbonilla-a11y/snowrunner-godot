extends Node

signal trailer_comprado(trailer_id: String)
signal trailer_equipado(trailer_id: String)

var trailers_disponibles: Array = []
var trailers_propios: Array = []  # Trailers en el patio del jugador
var trailer_equipado_actual: String = ""  # ID del trailer acoplado actualmente

func _ready() -> void:
	_inicializar_trailers()
	_sincronizar_con_global()

func _inicializar_trailers() -> void:
	trailers_disponibles.clear()
	
	# Remolque Básico
	var t1 = load("res://gameplay/vehicles/trailers/data/trailer_basico_data.tres") as TrailerData
	trailers_disponibles.append(t1)
	
	# Remolque de Carga
	var t2 = load("res://gameplay/vehicles/trailers/data/trailer_carga_data.tres") as TrailerData
	trailers_disponibles.append(t2)
	
	# Remolque de Carga Larga
	var t3 = load("res://gameplay/vehicles/trailers/data/trailer_carga_largue_data.tres") as TrailerData
	trailers_disponibles.append(t3)

func _sincronizar_con_global() -> void:
	trailers_propios = GlobalData.patio_remolques.duplicate()

func get_trailer_data(trailer_id: String) -> TrailerData:
	for t in trailers_disponibles:
		if t.ruta_escena == trailer_id or t.ruta_escena.get_file() == trailer_id or t.nombre == trailer_id:
			return t
	return null

func comprar_trailer(trailer_id: String) -> bool:
	var data = get_trailer_data(trailer_id)
	if not data:
		return false
	
	if GlobalData.dinero < data.precio:
		print("Dinero insuficiente para comprar ", data.nombre)
		return false
	
	if ya_tiene_trailer(data.ruta_escena):
		print("Ya tienes este remolque")
		return false
	
	GlobalData.dinero -= data.precio
	var trailer_data = {
		"ruta_escena": data.ruta_escena,
		"nombre": data.nombre,
		"tipo": data.tipo,
		"masa": data.masa,
		"capacidad_carga": data.capacidad_carga,
		"slots_carga": data.slots_carga
	}
	trailers_propios.append(trailer_data)
	GlobalData.patio_remolques.append(trailer_data)
	print("Comprado: ", data.nombre, ". Dinero restante: $", GlobalData.dinero)
	trailer_comprado.emit(data.ruta_escena)
	return true

func ya_tiene_trailer(ruta: String) -> bool:
	for t in trailers_propios:
		if t["ruta_escena"] == ruta:
			return true
	return false

func equipar_trailer(trailer_index: int) -> bool:
	if trailer_index < 0 or trailer_index >= trailers_propios.size():
		return false
	
	var trailer = trailers_propios[trailer_index]
	trailer_equipado_actual = trailer["ruta_escena"]
	print("Equipado: ", trailer["nombre"])
	trailer_equipado.emit(trailer["ruta_escena"])
	return true

func desequipar_trailer() -> void:
	trailer_equipado_actual = ""
	print("Remolque desequipado")

func get_trailer_equipado() -> Dictionary:
	for t in trailers_propios:
		if t["ruta_escena"] == trailer_equipado_actual:
			return t
	return {}

func get_trailers_propios() -> Array:
	return trailers_propios

func get_trailers_disponibles() -> Array:
	return trailers_disponibles