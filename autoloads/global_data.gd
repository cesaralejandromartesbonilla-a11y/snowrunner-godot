extends Node

const RUTA_GUARDADO = "user://partida_guardada.save"

var hay_partida_activa: bool = false
var mapa_actual_guardado: String = ""
var dinero: int = 0

var slot_activo: int = 0
var garaje_slots: Array = []
var almacen_vehiculos: Array = []
var patio_remolques: Array = []  # Remolques en el patio

const CATALOGO_VEHICULOS: Array = [
	{
		"id": "ck1500",
		"nombre": "Chevrolet CK1500",
		"clase": "Scout",
		"precio": 0,
		"descripcion": "Ligero y ágil. Ideal para exploración.",
		"ruta_escena": "res://gameplay/vehicles/ck1500.tscn",
		"awd": "Switchable",
		"diff": "Upgrade needed",
		"masa": "2,000 kg",
		"fuel": "80 L"
	},
	{
		"id": "fleetstar",
		"nombre": "Fleetstar F2070A",
		"clase": "Heavy Duty",
		"precio": 800,
		"descripcion": "El tractor de trabajo. Versátil y fiable.",
		"ruta_escena": "res://gameplay/vehicles/fleetstar.tscn",
		"awd": "Upgrade needed",
		"diff": "Switchable",
		"masa": "6,300 kg",
		"fuel": "240 L"
	},
	{
		"id": "atom",
		"nombre": "Azov 67096 Atom",
		"clase": "Heavy",
		"precio": 2500,
		"descripcion": "Potencia bruta con diff siempre activo.",
		"ruta_escena": "res://gameplay/vehicles/atom.tscn",
		"awd": "Switchable",
		"diff": "Always On",
		"masa": "15,528 kg",
		"fuel": "350 L"
	},
	{
		"id": "k700",
		"nombre": "Kirovets K-700",
		"clase": "Special",
		"precio": 2000,
		"descripcion": "Articulado. Tracción always-on, perfecto para terreno difícil.",
		"ruta_escena": "res://gameplay/vehicles/k700.tscn",
		"awd": "Always On",
		"diff": "Switchable",
		"masa": "12,008 kg",
		"fuel": "340 L"
	},
	{
		"id": "p16",
		"nombre": "Pacific P16",
		"clase": "Super Heavy",
		"precio": 3500,
		"descripcion": "El gigante. Sin AWD pero con diff siempre activo.",
		"ruta_escena": "res://gameplay/vehicles/p16.tscn",
		"awd": "NONE",
		"diff": "Always On",
		"masa": "25,000 kg",
		"fuel": "300 L"
	},
	{
		"id": "kolob",
		"nombre": "KOLOB 74941",
		"clase": "Super Heavy",
		"precio": 4000,
		"descripcion": "Torque extremo. Para las cargas más pesadas.",
		"ruta_escena": "res://gameplay/vehicles/kolob.tscn",
		"awd": "Switchable",
		"diff": "Switchable",
		"masa": "26,500 kg",
		"fuel": "340 L"
	}
]

func _ready() -> void:
	_inicializar_garaje()
	cargar_partida()

func _inicializar_garaje() -> void:
	for i in range(5):
		garaje_slots.append({
			"ocupado": false,
			"ruta_escena": "",
			"etiquetas_actuales": []
		})
	garaje_slots[0]["ocupado"] = true
	garaje_slots[0]["ruta_escena"] = "res://gameplay/vehicles/ck1500.tscn"
	garaje_slots[0]["etiquetas_actuales"] = ["explorador", "ligero"]
	patio_remolques.clear()

func obtener_datos_vehiculo_activo() -> Dictionary:
	return garaje_slots[slot_activo]

# --- TIENDA ---

func comprar_vehiculo(catalogo_entry: Dictionary) -> bool:
	if dinero < catalogo_entry["precio"]:
		print("Dinero insuficiente. Necesitas $", catalogo_entry["precio"])
		return false
	dinero -= catalogo_entry["precio"]
	almacen_vehiculos.append({
		"ruta_escena": catalogo_entry["ruta_escena"],
		"nombre": catalogo_entry["nombre"],
		"etiquetas_actuales": []
	})
	print("Comprado: ", catalogo_entry["nombre"], ". Dinero restante: $", dinero)
	return true

func ya_comprado(catalogo_id: String) -> bool:
	for slot in garaje_slots:
		if slot["ocupado"] and slot["ruta_escena"].find(catalogo_id) != -1:
			return true
	for v in almacen_vehiculos:
		if v["ruta_escena"].find(catalogo_id) != -1:
			return true
	return false

# --- ALMACEN ---

func mover_a_garaje(almacen_index: int, slot_index: int) -> bool:
	if almacen_index < 0 or almacen_index >= almacen_vehiculos.size():
		return false
	if slot_index < 0 or slot_index >= 5:
		return false
	if garaje_slots[slot_index]["ocupado"]:
		print("Slot ocupado, guarda el vehículo actual primero.")
		return false
	var vehiculo = almacen_vehiculos[almacen_index]
	garaje_slots[slot_index]["ocupado"] = true
	garaje_slots[slot_index]["ruta_escena"] = vehiculo["ruta_escena"]
	garaje_slots[slot_index]["etiquetas_actuales"] = vehiculo.get("etiquetas_actuales", [])
	almacen_vehiculos.remove_at(almacen_index)
	return true

func mover_a_almacen(slot_index: int) -> bool:
	if slot_index < 0 or slot_index >= 5:
		return false
	if slot_index == 0:
		print("No puedes vaciar el slot inicial.")
		return false
	if not garaje_slots[slot_index]["ocupado"]:
		return false
	var slot = garaje_slots[slot_index]
	almacen_vehiculos.append({
		"ruta_escena": slot["ruta_escena"],
		"nombre": _nombre_desde_ruta(slot["ruta_escena"]),
		"etiquetas_actuales": slot.get("etiquetas_actuales", [])
	})
	slot["ocupado"] = false
	slot["ruta_escena"] = ""
	slot["etiquetas_actuales"] = []
	return true

func _nombre_desde_ruta(ruta: String) -> String:
	for c in CATALOGO_VEHICULOS:
		if c["ruta_escena"] == ruta:
			return c["nombre"]
	return "Desconocido"

# --- GUARDADO ---

func guardar_partida(ruta_mapa: String = "") -> void:
	var archivo = FileAccess.open(RUTA_GUARDADO, FileAccess.WRITE)
	if archivo:
		if ruta_mapa != "":
			mapa_actual_guardado = ruta_mapa
		var datos_a_guardar = {
			"garaje": garaje_slots,
			"mapa": mapa_actual_guardado,
			"activa": true,
			"dinero": dinero,
			"almacen": almacen_vehiculos,
			"patio_remolques": patio_remolques
		}
		archivo.store_var(datos_a_guardar)
		archivo.close()
		print("Partida guardada con éxito en: ", RUTA_GUARDADO)

func cargar_partida() -> void:
	if FileAccess.file_exists(RUTA_GUARDADO):
		var archivo = FileAccess.open(RUTA_GUARDADO, FileAccess.READ)
		if archivo:
			var datos_cargados = archivo.get_var()
			garaje_slots = datos_cargados["garaje"]
			mapa_actual_guardado = datos_cargados["mapa"]
			hay_partida_activa = datos_cargados["activa"]
			dinero = datos_cargados.get("dinero", 0)
			almacen_vehiculos = datos_cargados.get("almacen", [])
			patio_remolques = datos_cargados.get("patio_remolques", [])
			archivo.close()
			print("Partida cargada. Mapa guardado: ", mapa_actual_guardado)
	else:
		print("No hay partida guardada. Es un jugador nuevo.")

func borrar_partida() -> void:
	if FileAccess.file_exists(RUTA_GUARDADO):
		var dir = DirAccess.open("user://")
		dir.remove("partida_guardada.save")
	hay_partida_activa = false
	mapa_actual_guardado = ""
	dinero = 0
	garaje_slots.clear()
	almacen_vehiculos.clear()
	patio_remolques.clear()
	_inicializar_garaje()
