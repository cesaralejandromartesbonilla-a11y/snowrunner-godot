extends Control

@onready var lista_categorias = $Margen/ContenedorPrincipal/ListaCategorias
@onready var contenedor_botones = $Margen/ContenedorPrincipal/ScrollContainer/ContenedorBotones
@onready var detalles_pieza = $Margen/ContenedorPrincipal/DetallesPieza
@onready var btn_cerrar = $Margen/ContenedorPrincipal/BtnCerrarMenu

var base_datos = {
	"Motor": [
		{"id": "v8_2.4L", "nombre": "Motor V8 2.4L", "ruta": "res://data/engines/v8_24l.tres"},
		{"id": "i6_4.0L", "nombre": "Motor I6 4.0L", "ruta": "res://data/engines/i6_40l.tres"}
	],
	"Caja de Cambios": [
		{"clase": "explorador", "nombre": "Caja OffRoad", "ruta": "res://data/gearboxes/offroad_exp.tres"},
		{"clase": "camion_pesado", "nombre": "Caja Arrastre 12 Vel", "ruta": "res://data/gearboxes/arrastre_12.tres"}
	],
	"Llantas": [
		{"pulgadas": 28.0, "nombre": "Llantas Barro 28\"", "ruta": "res://data/tires/barro_28.tres"},
		{"pulgadas": 30.0, "nombre": "Llantas Todoterreno 30\"", "ruta": "res://data/tires/at_30.tres"},
		{"pulgadas": 38.0, "nombre": "Llantas Monstruo 38\"", "ruta": "res://data/tires/monster_38.tres"}
	],
	"Añadidos": [
		{"paquete": "paquete_basico", "nombre": "Quinta Rueda", "ruta": "res://data/addons_data/quinta_rueda.tres"},
		{"paquete": "paquete_pesos", "nombre": "Peso Muerto (5t)", "ruta": "res://data/addons_data/peso_5t.tres"}
	],
	"Add-ons": [
		{"nombre": "Quinta Rueda", "ruta": "res://gameplay/vehicles/addons/saddle_addon.tres", "slot": "frame"},
		{"nombre": "Cama Plana (Flatbed)", "ruta": "res://gameplay/vehicles/addons/flatbed_addon.tres", "slot": "frame"},
		{"nombre": "Portatroncos", "ruta": "res://gameplay/vehicles/addons/log_carrier_addon.tres", "slot": "frame"},
		{"nombre": "Grua de Carga", "ruta": "res://gameplay/vehicles/addons/crane_addon.tres", "slot": "frame"},
		{"nombre": "Tanque Combustible Auxiliar", "ruta": "res://gameplay/vehicles/addons/fuel_tank_addon.tres", "slot": "frame"},
		{"nombre": "Winch Eléctrico", "ruta": "res://gameplay/vehicles/addons/winch_addon.tres", "slot": "front"},
		{"nombre": "Snorkel", "ruta": "res://gameplay/vehicles/addons/snorkel_addon.tres", "slot": "front"}
	]
}

var vehiculo_actual_datos: Dictionary

func _ready() -> void:
	lista_categorias.item_selected.connect(_filtrar_categoria)
	btn_cerrar.pressed.connect(cerrar_menu)
	
	lista_categorias.add_item("Motor")
	lista_categorias.add_item("Caja de Cambios")
	lista_categorias.add_item("Llantas")
	lista_categorias.add_item("Añadidos")
	lista_categorias.add_item("Add-ons")

func abrir_menu(datos_vehiculo: Dictionary) -> void:
	vehiculo_actual_datos = datos_vehiculo
	show()
	lista_categorias.select(0)
	_filtrar_categoria(0)

func cerrar_menu() -> void:
	hide()

func _filtrar_categoria(index: int) -> void:
	for hijo in contenedor_botones.get_children():
		hijo.queue_free()
	
	var categoria = lista_categorias.get_item_text(index)
	var datos_v = GlobalData.obtener_datos_vehiculo_activo()
	var specs = datos_v.get("especificaciones", {})
	
	print("Filtrando: ", categoria)
	
	for pieza in base_datos[categoria]:
		var mostrar = true
		
		match categoria:
			"Motor":
				var req = specs.get("motor_estricto", "")
				if req != "" and pieza["id"] != req: mostrar = false
			"Llantas":
				var ideal = specs.get("llanta_ideal_pulgadas", 0.0)
				if ideal != 0.0 and abs(pieza["pulgadas"] - ideal) > 10.0: mostrar = false
			"Add-ons":
				var vehiculo = _get_vehiculo_instanciado()
				if vehiculo and vehiculo.has_method("tiene_addon"):
					if vehiculo.tiene_addon(AddOnData.TipoAddOn[pieza["slot"].to_upper()]):
						mostrar = false  # Ya equipado en ese slot
		
		if mostrar:
			_crear_boton_pieza(categoria, pieza)

func _get_vehiculo_instanciado() -> Node:
	var slot = GlobalData.slot_activo
	var vehiculos = get_tree().get_nodes_in_group("jugador")
	for v in vehiculos:
		if v.get_instance_id() == slot:
			return v
	return null

func _crear_boton_pieza(categoria: String, pieza: Dictionary) -> void:
	var btn = Button.new()
	btn.text = pieza["nombre"]
	btn.custom_minimum_size = Vector2(0, 60)
	
	if categoria == "Add-ons":
		btn.tooltip_text = "Slot: %s" % pieza["slot"]
		btn.pressed.connect(_equipar_addon.bind(pieza["ruta"], pieza["nombre"], pieza["slot"]))
	else:
		btn.pressed.connect(_equipar_pieza.bind(categoria, pieza["ruta"], pieza["nombre"]))
	
	contenedor_botones.add_child(btn)
	print("Botón creado: ", pieza["nombre"])

func _equipar_pieza(categoria: String, ruta: String, nombre_pieza: String) -> void:
	if categoria == "Motor":
		vehiculo_actual_datos["ruta_motor"] = ruta
	elif categoria == "Llantas":
		vehiculo_actual_datos["ruta_llantas"] = ruta
	elif categoria == "Caja de Cambios":
		vehiculo_actual_datos["ruta_caja"] = ruta
	elif categoria == "Añadidos":
		vehiculo_actual_datos["ruta_addon"] = ruta
	
	detalles_pieza.text = "¡INSTALADO EXITOSAMENTE!\n" + nombre_pieza
	print("Se equipó: ", nombre_pieza, " (", ruta, ")")

func _equipar_addon(ruta: String, nombre: String, slot: String) -> void:
	var vehiculo = _get_vehiculo_instanciado()
	if not vehiculo:
		detalles_pieza.text = "Error: No hay vehículo instanciado"
		return
	
	var addon = load(ruta) as AddOnData
	if not addon:
		detalles_pieza.text = "Error: No se pudo cargar addon"
		return
	
	# Buscar slot marker en el vehículo
	var slot_marker = _buscar_slot_marker(vehiculo, slot)
	if not slot_marker:
		detalles_pieza.text = "Error: Slot %s no encontrado" % slot
		return
	
	if vehiculo.has_method("equipar_addon"):
		vehiculo.equipar_addon(addon, slot_marker)
		detalles_pieza.text = "ADD-ON INSTALADO!\n%s (%s)" % [nombre, slot]
		print("Add-on equipado: ", nombre, " en slot ", slot)
	else:
		detalles_pieza.text = "Error: Vehículo no soporta add-ons"

func _buscar_slot_marker(vehiculo: Node, slot_tipo: String) -> Marker3D:
	match slot_tipo:
		"frame":
			if vehiculo.has_node("QuintaRueda"):
				return vehiculo.get_node("QuintaRueda")
		"front":
			if vehiculo.has_node("FrontBumper"):
				return vehiculo.get_node("FrontBumper")
	
	# Fallback: crear marker temporal
	var marker = Marker3D.new()
	marker.name = "TempSlot_%s" % slot_tipo
	marker.transform = Transform3D(Basis.IDENTITY, Vector3(0, 1.0, -1.0))
	vehiculo.add_child(marker)
	return marker
