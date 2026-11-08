extends CanvasLayer

var label_contrato: Label
var label_objetivo: Label
var label_dinero: Label
var brújula: Control
var flecha: TextureRect
var _objetivo_pos: Vector3 = Vector3.ZERO

func _ready() -> void:
	add_to_group("hud")
	_build_ui()
	ContratoManager.contrato_aceptado.connect(_on_contrato_aceptado)
	ContratoManager.carga_recogida.connect(_on_carga_recogida)
	ContratoManager.contrato_completado.connect(_on_contrato_completado)

func _build_ui() -> void:
	# Panel principal (arriba-izquierda)
	var margin = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_TOP_LEFT)
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.custom_minimum_size = Vector2(250, 0)
	add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	margin.add_child(vbox)
	
	label_dinero = Label.new()
	label_dinero.add_theme_font_size_override("font_size", 16)
	label_dinero.text = "Dinero: $%d" % GlobalData.dinero
	vbox.add_child(label_dinero)
	
	label_contrato = Label.new()
	label_contrato.add_theme_font_size_override("font_size", 14)
	label_contrato.text = ""
	vbox.add_child(label_contrato)
	
	label_objetivo = Label.new()
	label_objetivo.add_theme_font_size_override("font_size", 12)
	label_objetivo.modulate = Color(1, 1, 0.6)
	label_objetivo.text = ""
	vbox.add_child(label_objetivo)
	
	# Brújula/flecha (arriba-centro)
	brújula = _crear_brújula()
	brújula.set_anchors_preset(Control.PRESET_CENTER_TOP)
	brújula.offset_top = 10
	brújula.custom_minimum_size = Vector2(120, 120)
	add_child(brújula)

func _crear_brújula() -> Control:
	var container = Control.new()
	
	# Fondo circular
	var fondo = TextureRect.new()
	fondo.custom_minimum_size = Vector2(100, 100)
	fondo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	var img = Image.create(100, 100, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	# Dibujar círculo
	for x in range(100):
		for y in range(100):
			var dx = x - 50
			var dy = y - 50
			var dist = sqrt(dx*dx + dy*dy)
			if dist >= 45 and dist <= 50:
				img.set_pixel(x, y, Color(0.3, 0.3, 0.3, 0.8))
			elif dist < 45:
				img.set_pixel(x, y, Color(0, 0, 0, 0.4))
	var tex = ImageTexture.create_from_image(img)
	fondo.texture = tex
	fondo.set_anchors_preset(Control.PRESET_CENTER)
	fondo.offset_left = -50
	fondo.offset_top = -50
	container.add_child(fondo)
	
	# Norte (N)
	var lbl_n = Label.new()
	lbl_n.text = "N"
	lbl_n.add_theme_font_size_override("font_size", 10)
	lbl_n.modulate = Color(0.7, 0.7, 0.7)
	lbl_n.set_anchors_preset(Control.PRESET_CENTER_TOP)
	lbl_n.offset_top = 5
	lbl_n.offset_left = -8
	container.add_child(lbl_n)
	
	# Flecha que rota
	flecha = TextureRect.new()
	flecha.custom_minimum_size = Vector2(20, 60)
	flecha.set_anchors_preset(Control.PRESET_CENTER)
	flecha.offset_left = -10
	flecha.offset_top = -30
	flecha.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	
	# Crear textura de flecha - base en el centro (pivot), punta arriba
	var arrow_img = Image.create(20, 60, false, Image.FORMAT_RGBA8)
	arrow_img.fill(Color(0, 0, 0, 0))
	# Centro de la textura (punto de rotación) = (10, 30)
	var center_x = 10
	var center_y = 30
	var arrow_length = 30  # punta a 30px arriba del centro
	var tail_length = 25   # cola a 25px abajo del centro
	var max_width = 10
	
	for x in range(20):
		for y in range(60):
			var cx = x - center_x
			var cy = y - center_y
			# Flecha apunta hacia ARRIBA (cy negativo)
			if cy <= 0 and cy >= -arrow_length:
				# Triángulo: ancho proporcional a la distancia de la punta
				var t = 1.0 - float(-cy) / arrow_length
				var width_at_y = max_width * t
				if abs(cx) < width_at_y:
					arrow_img.set_pixel(x, y, Color(1, 0.8, 0, 1))
			# Cola de la flecha (debajo del centro)
			elif cy > 0 and cy <= tail_length and abs(cx) < 3:
				arrow_img.set_pixel(x, y, Color(1, 0.8, 0, 0.8))
	var arrow_tex = ImageTexture.create_from_image(arrow_img)
	flecha.texture = arrow_tex
	container.add_child(flecha)
	
	return container

func _process(_delta: float) -> void:
	if label_dinero:
		label_dinero.text = "Dinero: $%d" % GlobalData.dinero
	
	var contrato = ContratoManager.get_contrato_activo()
	if contrato:
		label_contrato.text = "Contrato: %s" % contrato.nombre
		match contrato.estado:
			ContratoData.EstadoContrato.ACEPTADO:
				label_objetivo.text = " -> Ve al punto de carga y presiona F"
			ContratoData.EstadoContrato.CARGA_RECOGIDA:
				label_objetivo.text = " -> Carga a bordo! Entrega en el destino"
			_:
				label_objetivo.text = ""
		_actualizar_brújula(contrato)
	else:
		label_contrato.text = "Sin contrato activo"
		label_objetivo.text = "Busca una tabla de contratos (F)"
		_objetivo_pos = Vector3.ZERO

func _actualizar_brújula(contrato: ContratoData) -> void:
	if not brújula or not flecha:
		return
	
	var vehiculo = _encontrar_jugador()
	if not vehiculo:
		return
	
	# Encontrar el marcador correspondiente
	var target_pos = _encontrar_marcador_objetivo(contrato)
	if target_pos == Vector3.ZERO:
		return
	
	_objetivo_pos = target_pos
	
	# Distancia
	var dist = vehiculo.global_position.distance_to(target_pos)
	if label_objetivo:
		var km = dist / 1000.0
		if km >= 1.0:
			label_objetivo.text += "  [%.1f km]" % km
		else:
			label_objetivo.text += "  [%d m]" % int(dist)
	
	# Calcular ángulo relativo al vehículo
	var dir_to_target = (target_pos - vehiculo.global_position).normalized()
	var vehicle_forward = -vehiculo.global_transform.basis.z.normalized()
	var vehicle_forward_2d = Vector2(vehicle_forward.x, vehicle_forward.z)
	var target_dir_2d = Vector2(dir_to_target.x, dir_to_target.z)
	
	var angle = vehicle_forward_2d.angle_to(target_dir_2d)
	
	# Rotar la flecha (negativo porque en 2D el Y positivo es abajo)
	flecha.rotation = -angle

func _encontrar_jugador() -> Node3D:
	var jugadores = get_tree().get_nodes_in_group("jugador")
	if jugadores.size() > 0:
		return jugadores[0]
	return null

func _encontrar_marcador_objetivo(contrato: ContratoData) -> Vector3:
	var buscar_pickup = (contrato.estado == ContratoData.EstadoContrato.ACEPTADO)
	
	for node in get_tree().get_nodes_in_group("contract_pickups"):
		if node.contrato_id == contrato.id:
			var is_pickup = node.usar_como_pickup
			if (buscar_pickup and is_pickup) or (not buscar_pickup and not is_pickup):
				return node.global_position
	return Vector3.ZERO

func _on_contrato_aceptado(nombre: String) -> void:
	pass

func _on_carga_recogida(nombre: String) -> void:
	pass

func _on_contrato_completado(nombre: String, recompensa: int) -> void:
	pass
