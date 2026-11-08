extends VehicleBody3D

# ─── SEÑALES ───
signal datos_actualizados(combustible: float, velocidad: float, rpm: float, marcha: String)
signal traccion_cambiada(es_4x4: bool)
signal motor_estado_cambiado(encendido: bool)
signal dif_cambiado(bloqueado: bool)
signal marcha_cambiada(marcha: String)

# ─── CONFIGURACIÓN ───
@export var stats: VehicleStats

# ─── ESTADO DEL MOTOR ───
var motor_encendido: bool = false
var combustible_actual: float = 0.0
var rpm_actual: float = 0.0
var temperatura_motor: float = 20.0

# ─── TRANSMISIÓN ───
var es_4x4: bool = false
var dif_bloqueado: bool = false
var marcha_actual: int = 0  # R=-3, N=-2, L=-1, 1=0, 2=1, 3=2, 4=3
var automatico: bool = true
var velocidad_anterior: float = 0.0

# ─── TERRENO ───
var terreno_bajo_vehiculo: String = "desconocido"
var detectores_rueda: Array[WheelTerrainDetector] = []

# ─── REMOLQUE ───
var remolque_acoplado: Node3D = null
var joint_acople: Joint3D = null

# ─── CARGA ───
var tiene_carga: bool = false

func _ready() -> void:
	if stats:
		mass = stats.masa
		combustible_actual = stats.combustible_max
		_apply_vehicle_quirks()
	
	_inicializar_detectores()

func _apply_vehicle_quirks() -> void:
	if not stats:
		return
	
	# P16: NO AWD (AWDMode.NONE)
	if stats.awd_mode == VehicleStats.AWDMode.NONE:
		es_4x4 = false
		print("%s: Sin AWD (tracción trasera only)" % stats.nombre)
	else:
		es_4x4 = (stats.awd_mode == VehicleStats.AWDMode.ALWAYS_ON)
	
	# Atom: Diff siempre activo
	if stats.diff_mode == VehicleStats.DiffMode.ALWAYS_ON:
		dif_bloqueado = true
		print("%s: Diff siempre BLOQUEADO" % stats.nombre)
	else:
		dif_bloqueado = (stats.diff_mode == VehicleStats.DiffMode.ALWAYS_ON)
	
	# K-700: Articulado (se maneja con 2 VehicleBody3D en escena separada)
	if stats.nombre == "Kirovets K-700":
		print("%s: Chasis articulado" % stats.nombre)
	
	# KOLOB: Switchable AWD + Switchable Diff
	if stats.nombre == "KOLOB 74941":
		print("%s: AWD y Diff switchable" % stats.nombre)

func _inicializar_detectores() -> void:
	for child in get_children():
		if child is VehicleWheel3D:
			var detector = WheelTerrainDetector.new()
			detector.setup(child)
			child.add_child(detector)
			detectores_rueda.append(detector)

func _physics_process(delta: float) -> void:
	_gestionar_inputs()
	actualizar_terreno()
	_aplicar_motor(delta)
	_aplicar_terreno(delta)
	_consumir_combustible(delta)
	_actualizar_rpm(delta)
	_shifting_automatico()
	
	var vel = linear_velocity.length() * 3.6
	var marcha_nombre = stats.get_gear_name(marcha_actual) if stats else "?"
	datos_actualizados.emit(combustible_actual, vel, rpm_actual, marcha_nombre)

# ─── INPUTS ───
func _gestionar_inputs() -> void:
	if Input.is_action_just_pressed("press_e"):
		if combustible_actual > 0:
			motor_encendido = !motor_encendido
			motor_estado_cambiado.emit(motor_encendido)
	
	if stats and stats.awd_mode == VehicleStats.AWDMode.SWITCHABLE:
		if Input.is_action_just_pressed("press_t"):
			es_4x4 = !es_4x4
			traccion_cambiada.emit(es_4x4)
	
	if stats and stats.diff_mode == VehicleStats.DiffMode.SWITCHABLE:
		if Input.is_action_just_pressed("press_z"):
			dif_bloqueado = !dif_bloqueado
			dif_cambiado.emit(dif_bloqueado)
	
	_gestionar_marchas()
	
	if Input.is_action_just_pressed("press_f"):
		if tiene_carga:
			_entregar_carga()
		elif remolque_acoplado:
			_desacoplar()
		else:
			_intentar_acoplar_o_cargar()

func _gestionar_marchas() -> void:
	if not stats:
		return
	
	var gas = Input.get_axis("press_s", "press_w")
	var vel = linear_velocity.length() * 3.6
	
	if Input.is_action_just_pressed("press_r"):
		automatico = !automatico
		return
	
	if not automatico:
		if Input.is_action_just_pressed("press_+"):
			if marcha_actual < stats.get_gear_count() - 1:
				marcha_actual += 1
				marcha_cambiada.emit(stats.get_gear_name(marcha_actual))
		elif Input.is_action_just_pressed("press_-"):
			if marcha_actual > -3:
				marcha_actual -= 1
				marcha_cambiada.emit(stats.get_gear_name(marcha_actual))

# ─── MOTOR ───
func _aplicar_motor(delta: float) -> void:
	if not stats:
		return
	
	var aceleracion = 0.0
	var direccion = Input.get_axis("press_d", "press_a")
	
	if motor_encendido and combustible_actual > 0:
		aceleracion = Input.get_axis("press_s", "press_w")
	else:
		aceleracion = 0.0
		if combustible_actual <= 0:
			motor_encendido = false
	
	steering = move_toward(steering, direccion * stats.steering_max, stats.steering_speed * delta)
	
	if marcha_actual == -2:
		for wheel in get_children():
			if wheel is VehicleWheel3D:
				wheel.engine_force = 0.0
		return
	
	var ratio_marcha = _get_ratio_actual()
	var friccion_media = _get_friccion_media()
	
	var ratio_velocidad = clamp(linear_velocity.length() / 25.0, 0.0, 1.0)
	var torque_curva_val = stats.curva_torque.sample(ratio_velocidad) if stats.curva_torque else 0.5
	
	var fuerza_base = aceleracion * stats.max_torque * torque_curva_val * ratio_marcha * stats.ratio_diferencial
	
	for wheel in get_children():
		if wheel is VehicleWheel3D:
			var es_trasera = wheel.position.z > 0
			var es_motriz = es_trasera or es_4x4
			
			if es_motriz:
				var fuerza_rueda = fuerza_base
				if dif_bloqueado:
					fuerza_rueda *= 1.1
				wheel.engine_force = fuerza_rueda * friccion_media
			else:
				wheel.engine_force = 0.0
			
			var slip_base = stats.friction_slip_base if stats else 2.0
			var slip_diff = stats.friction_slip_diff if stats else 5.0
			wheel.wheel_friction_slip = slip_base + (slip_diff if dif_bloqueado else 0.0)
			wheel.wheel_friction_slip *= friccion_media
			
			if aceleracion == 0 and linear_velocity.length() < 1.0 and marcha_actual != -2:
				wheel.brake = 5.0
			else:
				wheel.brake = 0.0

func _get_ratio_actual() -> float:
	if not stats:
		return 1.0
	
	match marcha_actual:
		-3: return stats.ratio_reversa
		-1: return stats.ratios[0] if stats.ratios.size() > 0 else 4.0
		0: return stats.ratios[1] if stats.ratios.size() > 1 else 2.5
		1: return stats.ratios[2] if stats.ratios.size() > 2 else 1.6
		2: return stats.ratios[3] if stats.ratios.size() > 3 else 1.0
		3: return stats.ratios[4] if stats.ratios.size() > 4 else 0.7
	return 1.0

# ─── TERRENO ───
func actualizar_terreno() -> void:
	var tipos_vistos: Dictionary = {}
	for detector in detectores_rueda:
		if detector.terreno_actual != "desconocido":
			tipos_vistos[detector.terreno_actual] = tipos_vistos.get(detector.terreno_actual, 0) + 1
	
	if tipos_vistos.is_empty():
		terreno_bajo_vehiculo = "desconocido"
		return
	
	var mejor_tipo = "desconocido"
	var mayor_cantidad = 0
	for tipo in tipos_vistos:
		if tipos_vistos[tipo] > mayor_cantidad:
			mayor_cantidad = tipos_vistos[tipo]
			mejor_tipo = tipo
	terreno_bajo_vehiculo = mejor_tipo

func _get_friccion_media() -> float:
	if detectores_rueda.is_empty():
		return 1.0
	
	var total = 0.0
	for detector in detectores_rueda:
		total += detector.friccion_terreno
	return total / detectores_rueda.size()

func _aplicar_terreno(_delta: float) -> void:
	if terreno_bajo_vehiculo == "desconocido":
		return
	
	var datos = TerrainManager.get_datos(terreno_bajo_vehiculo)
	if datos["resistencia"] > 0 and linear_velocity.length() > 0.1:
		var resistencia = -linear_velocity.normalized() * datos["resistencia"] * mass * 0.001
		apply_central_force(resistencia)
	
	if datos["es_liquido"]:
		var dano = datos["dano_agua"] * _delta
		if dano > 0:
			combustible_actual -= dano * 0.1

# ─── COMBUSTIBLE ───
func _consumir_combustible(delta: float) -> void:
	if not stats or not motor_encendido:
		return
	
	var base = stats.consumo_base
	var gas = abs(Input.get_axis("press_s", "press_w"))
	base += gas * 0.3
	if es_4x4: base *= 1.15
	if dif_bloqueado: base *= 1.05
	
	var factor_marcha = 1.0
	if marcha_actual == -1:
		factor_marcha = 1.2
	
	combustible_actual -= base * factor_marcha * delta
	combustible_actual = clamp(combustible_actual, 0.0, stats.combustible_max)

# ─── RPM ───
func _actualizar_rpm(_delta: float) -> void:
	if not motor_encendido:
		rpm_actual = 0.0
		return
	
	var vel = linear_velocity.length()
	var ratio = _get_ratio_actual()
	
	if ratio > 0 and marcha_actual != -2:
		rpm_actual = clamp((vel * ratio * 10.0) + stats.rpm_min, stats.rpm_min, stats.max_rpm)
	else:
		rpm_actual = stats.rpm_min

# ─── SHIFTING AUTOMÁTICO ───
func _shifting_automatico() -> void:
	if not automatico or not stats:
		return
	
	var vel = linear_velocity.length() * 3.6
	var gas = Input.get_axis("press_s", "press_w")
	
	if marcha_actual < 0:
		return
	
	if gas > 0.1 and vel > 15.0 and marcha_actual < stats.get_gear_count() - 1:
		marcha_actual += 1
		marcha_cambiada.emit(stats.get_gear_name(marcha_actual))
	elif gas > 0.1 and vel < 8.0 and marcha_actual > 0:
		marcha_actual -= 1
		marcha_cambiada.emit(stats.get_gear_name(marcha_actual))
	elif gas < -0.1 and marcha_actual > 0:
		marcha_actual = -3
		marcha_cambiada.emit(stats.get_gear_name(marcha_actual))
	elif gas > -0.1 and marcha_actual == -3:
		marcha_actual = 0
		marcha_cambiada.emit(stats.get_gear_name(marcha_actual))

# ─── REMOLQUE ───
func _acoplar():
	if not stats:
		return
	var nodo_qr = get_node_or_null("QuintaRueda")
	if not nodo_qr:
		return
	
	var remolques = get_tree().get_nodes_in_group("remolques")
	for r in remolques:
		if r.has_node("PuntoPerno"):
			var dist = nodo_qr.global_position.distance_to(r.get_node("PuntoPerno").global_position)
			if dist < 3.0:
				_crear_joint(r, nodo_qr)
				return

func _intentar_acoplar_o_cargar():
	if not stats:
		return
	
	var cargas = get_tree().get_nodes_in_group("cargas")
	var nodo_qr = get_node_or_null("QuintaRueda")
	for carga in cargas:
		if carga is Node3D:
			var dist = global_position.distance_to(carga.global_position)
			if dist < 3.0 and not tiene_carga:
				if carga.has_method("recoger"):
					var data = carga.recoger()
					if data:
						tiene_carga = true
						return
	_acoplar()

func _crear_joint(remolque, nodo_qr):
	remolque_acoplado = remolque
	var offset = remolque.global_position - remolque.get_node("PuntoPerno").global_position
	remolque.global_position = nodo_qr.global_position + offset
	
	joint_acople = ConeTwistJoint3D.new()
	add_child(joint_acople)
	joint_acople.global_position = nodo_qr.global_position
	joint_acople.node_a = self.get_path()
	joint_acople.node_b = remolque.get_path()
	joint_acople.set_param(ConeTwistJoint3D.PARAM_SWING_SPAN, deg_to_rad(60))
	joint_acople.set_param(ConeTwistJoint3D.PARAM_TWIST_SPAN, deg_to_rad(20))
	
	add_collision_exception_with(remolque)
	if remolque.has_method("set_conectado"):
		remolque.set_conectado(true)

func acoplar_remolque_especifico(remolque: Node3D) -> bool:
	if not stats:
		return false
	var nodo_qr = get_node_or_null("QuintaRueda")
	if not nodo_qr:
		return false
	if not remolque.has_node("PuntoAcopleRemolque"):
		return false
	
	var dist = nodo_qr.global_position.distance_to(remolque.get_node("PuntoAcopleRemolque").global_position)
	if dist > 10.0:
		return false
	
	_crear_joint(remolque, nodo_qr)
	return true

func _desacoplar():
	if joint_acople:
		joint_acople.queue_free()
		joint_acople = null
	if remolque_acoplado:
		remove_collision_exception_with(remolque_acoplado)
		if remolque_acoplado.has_method("set_conectado"):
			remolque_acoplado.set_conectado(false)
		remolque_acoplado = null

# ─── INTERFACES EXTERNAS ───
func repostar(cantidad: float):
	combustible_actual += cantidad
	if stats:
		combustible_actual = clamp(combustible_actual, 0.0, stats.combustible_max)
	datos_actualizados.emit(combustible_actual, linear_velocity.length() * 3.6, rpm_actual, stats.get_gear_name(marcha_actual) if stats else "?")

func reparar():
	tiene_carga = false
	datos_actualizados.emit(combustible_actual, linear_velocity.length() * 3.6, rpm_actual, stats.get_gear_name(marcha_actual) if stats else "?")

func recibir_carga():
	tiene_carga = true

func entregar_carga():
	tiene_carga = false

func get_terrain_type() -> String:
	return terreno_bajo_vehiculo

func _entregar_carga():
	var zonas = get_tree().get_nodes_in_group("delivery_zones")
	for zona in zonas:
		if zona is Node3D:
			var dist = global_position.distance_to(zona.global_position)
			if dist < 5.0:
				tiene_carga = false
				if zona.has_method("cobrar"):
					zona.cobrar()
				return

# ─── ADD-ONS ───
var addons_equipados: Dictionary = {}

func _aplicar_addon(addon: AddOnData) -> void:
	if not addon:
		return
	addons_equipados[addon.tipo] = addon
	
	match addon.tipo:
		AddOnData.TipoAddOn.SADDLE:
			_crear_quinta_rueda()
			print("Saddle equipado - puede acoplar remolques")
		AddOnData.TipoAddOn.FLATBED:
			_crear_flatbed_slots()
			print("Flatbed equipado - slots de carga disponibles")
		AddOnData.TipoAddOn.LOG_CARRIER:
			_crear_log_carrier_slots()
			print("Log carrier equipado - para troncos")
		AddOnData.TipoAddOn.CRANE:
			_crear_grua()
			print("Crane equipado - autocarga disponible")
		AddOnData.TipoAddOn.FUEL_TANK:
			if stats:
				combustible_actual += addon.fuel_extra
				combustible_actual = min(combustible_actual, stats.combustible_max + addon.fuel_extra)
			print("Fuel tank equipado +", addon.fuel_extra, "L")
		AddOnData.TipoAddOn.WINCH:
			print("Winch equipado")
		AddOnData.TipoAddOn.SNORKEL:
			print("Snorkel equipado - mayor profundidad agua")

func _remover_addon(addon: AddOnData) -> void:
	if addons_equipados.has(addon.tipo):
		addons_equipados.erase(addon.tipo)
		print("Add-on removido: ", addon.nombre)

func _crear_quinta_rueda() -> void:
	if not has_node("QuintaRueda"):
		var marker = Marker3D.new()
		marker.name = "QuintaRueda"
		marker.transform = Transform3D(Basis.IDENTITY, Vector3(0, 0.45, -1.5))
		add_child(marker)
		print("Quinta rueda creada")

func _crear_flatbed_slots() -> void:
	var slots_node = Node3D.new()
	slots_node.name = "FlatbedSlots"
	for i in range(4):
		var slot = Marker3D.new()
		slot.name = "Slot%02d" % i
		slot.transform = Transform3D(Basis.IDENTITY, Vector3(-0.8 + i * 0.5, 0.6, 0.5))
		slots_node.add_child(slot)
	add_child(slots_node)

func _crear_log_carrier_slots() -> void:
	var slots_node = Node3D.new()
	slots_node.name = "LogCarrierSlots"
	for i in range(3):
		var slot = Marker3D.new()
		slot.name = "LogSlot%02d" % i
		slot.transform = Transform3D(Basis.IDENTITY, Vector3(-1.0 + i * 1.0, 0.8, 0.0))
		slots_node.add_child(slot)
	add_child(slots_node)

func _crear_grua() -> void:
	if not has_node("CranePivot"):
		var pivot = Node3D.new()
		pivot.name = "CranePivot"
		pivot.transform = Transform3D(Basis.IDENTITY, Vector3(0, 1.5, -1.0))
		add_child(pivot)
		print("Grua creada en pivot")

func get_slot_libre() -> Marker3D:
	# Buscar en flatbed
	if has_node("FlatbedSlots"):
		for slot in get_node("FlatbedSlots").get_children():
			if slot is Marker3D and not slot.get_meta("ocupado", false):
				return slot
	# Buscar en log carrier
	if has_node("LogCarrierSlots"):
		for slot in get_node("LogCarrierSlots").get_children():
			if slot is Marker3D and not slot.get_meta("ocupado", false):
				return slot
	return null

func _on_carga_acoplada(cargo: CargoData, slot: Marker3D) -> void:
	tiene_carga = true
	print("Vehículo recibió carga: ", cargo.nombre)

func _on_carga_desacoplada(cargo: CargoData) -> void:
	tiene_carga = false
	print("Vehículo liberó carga: ", cargo.nombre)

func equipar_addon(addon: AddOnData, slot_marker: Marker3D) -> void:
	if not slot_marker:
		return
	var addon_node = AddOnComponent.new()
	addon_node.addon_data = addon
	addon_node.equipar(self, slot_marker)

func get_addon_equipado(tipo: AddOnData.TipoAddOn) -> AddOnData:
	return addons_equipados.get(tipo)

func tiene_addon(tipo: AddOnData.TipoAddOn) -> bool:
	return addons_equipados.has(tipo)

func puede_acoplar_remolque() -> bool:
	return tiene_addon(AddOnData.TipoAddOn.SADDLE)

func get_puede_acoplar_carga() -> bool:
	return true  # Siempre puede recibir carga suelta
