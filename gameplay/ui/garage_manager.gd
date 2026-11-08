extends Node3D

@onready var camara = $CamaraGaraje
@onready var posiciones_vehiculos = $PosicionesVehiculos.get_children()
@onready var posiciones_camara = $PosicionesCamara.get_children()
@export var mapa_destino: PackedScene

@onready var btn_customizar = $UI_Garaje/PanelBotones/BtnCustomizar
@onready var btn_tienda = $UI_Garaje/PanelBotones/BtnTienda
@onready var btn_mapas = $UI_Garaje/PanelBotones/BtnMapas
@onready var btn_reparar = $UI_Garaje/PanelBotones/BtnReparar
@onready var btn_repostar = $UI_Garaje/PanelBotones/BtnRepostar
@onready var btn_almacen = $UI_Garaje/PanelBotones/BtnAlmacen
@onready var btn_patio_remolques = $UI_Garaje/PanelBotones/BtnPatioRemolques
@onready var btn_salir = $UI_Garaje/PanelBotones/BtnSalir
@onready var label_dinero = $UI_Garaje/PanelBotones/DineroLabel

@onready var btn_anterior = $UI_Garaje/NavegacionSlots/BtnAnterior
@onready var btn_siguiente = $UI_Garaje/NavegacionSlots/BtnSiguiente

@onready var tienda_ui = $UI_Garaje/TiendaUI
@onready var almacen_ui = $UI_Garaje/AlmacenUI
@onready var map_ui = $UI_Garaje/MapSelectionUI
@onready var trailer_yard_ui = $UI_Garaje/TrailerYardUI
@onready var patio_remolques = $PatioRemolques

var vehiculos_instanciados: Array = [null, null, null, null, null]
var remolques_instanciados: Array = [null, null, null, null, null]
var slot_actual: int = 0
var animando_camara: bool = false

const COSTO_REPARAR: int = 50
const COSTO_REPOSTAR: int = 20

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_conectar_botones()
	_cargar_vehiculos_del_global()
	slot_actual = GlobalData.slot_activo
	_mover_camara_inmediato(slot_actual)
	_actualizar_estado_botones()

func _conectar_botones() -> void:
	btn_anterior.pressed.connect(_on_btn_anterior_pressed)
	btn_siguiente.pressed.connect(_on_btn_siguiente_pressed)
	btn_customizar.pressed.connect(_on_btn_customizar_pressed)
	btn_tienda.pressed.connect(_on_btn_tienda_pressed)
	btn_mapas.pressed.connect(_on_btn_mapas_pressed)
	btn_reparar.pressed.connect(_on_btn_reparar_pressed)
	btn_repostar.pressed.connect(_on_btn_repostar_pressed)
	btn_almacen.pressed.connect(_on_btn_almacen_pressed)
	btn_patio_remolques.pressed.connect(_on_btn_patio_remolques_pressed)
	btn_salir.pressed.connect(_on_btn_salir_pressed)

func _cargar_vehiculos_del_global() -> void:
	for child in $PosicionesVehiculos.get_children():
		pass
	for i in range(5):
		var datos = GlobalData.garaje_slots[i]
		if datos["ocupado"] and datos["ruta_escena"] != "":
			var escena_vehiculo = load(datos["ruta_escena"]) as PackedScene
			if escena_vehiculo:
				var vehiculo = escena_vehiculo.instantiate()
				vehiculo.process_mode = Node.PROCESS_MODE_DISABLED
				vehiculo.global_transform = posiciones_vehiculos[i].global_transform
				add_child(vehiculo)
				vehiculos_instanciados[i] = vehiculo
	
	# Cargar remolques del patio
	_cargar_remolques_del_patio()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _cargar_remolques_del_patio() -> void:
	var posiciones_patio = patio_remolques.get_children()
	for i in range(min(5, GlobalData.patio_remolques.size())):
		var trailer_data = GlobalData.patio_remolques[i]
		if trailer_data["ruta_escena"] != "":
			var escena_trailer = load(trailer_data["ruta_escena"]) as PackedScene
			if escena_trailer:
				var trailer = escena_trailer.instantiate()
				trailer.process_mode = Node.PROCESS_MODE_DISABLED
				if i < posiciones_patio.size():
					trailer.global_transform = posiciones_patio[i].global_transform
				add_child(trailer)
				remolques_instanciados[i] = trailer

func _limpiar_vehiculos() -> void:
	for i in range(vehiculos_instanciados.size()):
		if vehiculos_instanciados[i] and is_instance_valid(vehiculos_instanciados[i]):
			vehiculos_instanciados[i].queue_free()
			vehiculos_instanciados[i] = null
	for i in range(remolques_instanciados.size()):
		if remolques_instanciados[i] and is_instance_valid(remolques_instanciados[i]):
			remolques_instanciados[i].queue_free()
			remolques_instanciados[i] = null

func _recargar_vehiculos() -> void:
	_limpiar_vehiculos()
	_cargar_vehiculos_del_global()
	_actualizar_estado_botones()

# --- CAMARA ---

func _mover_camara_inmediato(indice: int) -> void:
	var target = posiciones_camara[indice]
	camara.global_transform = target.global_transform

func _mover_camara_animada(indice: int) -> void:
	if animando_camara: return
	animando_camara = true
	var target = posiciones_camara[indice]
	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(camara, "global_position", target.global_position, 0.6)
	tween.tween_property(camara, "global_rotation", target.global_rotation, 0.6)
	tween.chain().tween_callback(func(): animando_camara = false)
	GlobalData.slot_activo = indice
	_actualizar_estado_botones()

func _actualizar_estado_botones() -> void:
	var ocupado = GlobalData.garaje_slots[slot_actual]["ocupado"]
	btn_customizar.disabled = !ocupado
	btn_reparar.disabled = !ocupado
	btn_repostar.disabled = !ocupado
	btn_salir.disabled = !ocupado
	btn_reparar.text = "Reparar ($%d)" % COSTO_REPARAR
	btn_repostar.text = "Repostar ($%d)" % COSTO_REPOSTAR
	if label_dinero:
		label_dinero.text = "Dinero: $%d" % GlobalData.dinero

# --- EVENTOS DE BOTONES ---

func _on_btn_anterior_pressed() -> void:
	if slot_actual > 0 and not animando_camara:
		slot_actual -= 1
		_mover_camara_animada(slot_actual)

func _on_btn_siguiente_pressed() -> void:
	if slot_actual < 4 and not animando_camara:
		slot_actual += 1
		_mover_camara_animada(slot_actual)

func _on_btn_customizar_pressed() -> void:
	$UI_Garaje/MenuCustomizacion.abrir_menu(GlobalData.obtener_datos_vehiculo_activo())

func _on_btn_tienda_pressed() -> void:
	tienda_ui.abrir()

func _on_btn_mapas_pressed() -> void:
	map_ui.abrir()

func _on_btn_reparar_pressed() -> void:
	var vehiculo = vehiculos_instanciados[slot_actual]
	if not vehiculo:
		return
	if GlobalData.dinero < COSTO_REPARAR:
		print("Dinero insuficiente para reparar. Necesitas $", COSTO_REPARAR)
		return
	GlobalData.dinero -= COSTO_REPARAR
	if vehiculo.has_method("reparar"):
		vehiculo.reparar()
	_actualizar_estado_botones()

func _on_btn_repostar_pressed() -> void:
	var vehiculo = vehiculos_instanciados[slot_actual]
	if not vehiculo:
		return
	if GlobalData.dinero < COSTO_REPOSTAR:
		print("Dinero insuficiente para repostar. Necesitas $", COSTO_REPOSTAR)
		return
	GlobalData.dinero -= COSTO_REPOSTAR
	if vehiculo.has_method("repostar") and vehiculo.get("stats"):
		vehiculo.repostar(vehiculo.stats.combustible_max)
	_actualizar_estado_botones()

func _on_btn_almacen_pressed() -> void:
	almacen_ui.abrir()

func _on_btn_patio_remolques_pressed() -> void:
	trailer_yard_ui.abrir()

func _on_btn_salir_pressed() -> void:
	GlobalData.guardar_partida()
	get_tree().change_scene_to_file("res://gameplay/maps/rio_negro.tscn")
