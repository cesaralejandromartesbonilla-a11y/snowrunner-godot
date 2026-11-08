extends CanvasLayer

var _lista: VBoxContainer
var _label_info: Label
var _boton_cerrar: Button

func _ready() -> void:
	visible = false
	_build_ui()

func _build_ui() -> void:
	var fondo = ColorRect.new()
	fondo.color = Color(0, 0, 0, 0.85)
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fondo)
	
	var margen = MarginContainer.new()
	margen.set_anchors_preset(Control.PRESET_FULL_RECT)
	margen.add_theme_constant_override("margin_left", 40)
	margen.add_theme_constant_override("margin_right", 40)
	margen.add_theme_constant_override("margin_top", 40)
	margen.add_theme_constant_override("margin_bottom", 40)
	add_child(margen)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	margen.add_child(vbox)
	
	var titulo = Label.new()
	titulo.text = "SELECCIONAR REMOLQUE"
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.add_theme_font_size_override("font_size", 22)
	vbox.add_child(titulo)
	
	_label_info = Label.new()
	_label_info.text = "Elige un remolque de tu patio para aparecer aquí"
	_label_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label_info.add_theme_font_size_override("font_size", 14)
	_label_info.modulate = Color(0.8, 0.8, 0.8)
	vbox.add_child(_label_info)
	
	vbox.add_child(HSeparator.new())
	
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size = Vector2(0, 250)
	vbox.add_child(scroll)
	
	_lista = VBoxContainer.new()
	_lista.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_lista.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.add_child(_lista)
	
	_boton_cerrar = Button.new()
	_boton_cerrar.text = "Cerrar (ESC)"
	_boton_cerrar.custom_minimum_size = Vector2(0, 40)
	_boton_cerrar.pressed.connect(cerrar)
	vbox.add_child(_boton_cerrar)

func abrir() -> void:
	show()
	_refrescar()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func cerrar() -> void:
	hide()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _refrescar() -> void:
	if not _lista:
		return
	for hijo in _lista.get_children():
		hijo.queue_free()
	
	var propios = TrailerManager.get_trailers_propios()
	if propios.is_empty():
		var lbl = Label.new()
		lbl.text = "No tienes remolques en el patio"
		lbl.modulate = Color(0.5, 0.5, 0.5)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_lista.add_child(lbl)
		return
	
	for i in range(propios.size()):
		_crear_tarjeta(propios[i], i)

func _crear_tarjeta(trailer: Dictionary, index: int) -> void:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 90)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	panel.add_child(vbox)
	
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	vbox.add_child(hbox)
	
	var info = VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(info)
	
	var lbl_nombre = Label.new()
	lbl_nombre.text = trailer["nombre"]
	lbl_nombre.add_theme_font_size_override("font_size", 16)
	info.add_child(lbl_nombre)
	
	var lbl_stats = Label.new()
	lbl_stats.text = "Masa: %.0fkg | Capacidad: %.0fkg | Slots: %d" % [trailer["masa"], trailer["capacidad_carga"], trailer["slots_carga"]]
	lbl_stats.add_theme_font_size_override("font_size", 12)
	info.add_child(lbl_stats)
	
	var equipado = (TrailerManager.trailer_equipado_actual == trailer["ruta_escena"])
	
	if equipado:
		var lbl_eq = Label.new()
		lbl_eq.text = "✓ EQUIPADO (presiona F para acoplar)"
		lbl_eq.add_theme_font_size_override("font_size", 12)
		lbl_eq.modulate = Color(0.5, 1, 0.5)
		info.add_child(lbl_eq)
	else:
		var btn = Button.new()
		btn.text = "Equipar y Spawnear Aquí"
		btn.custom_minimum_size = Vector2(180, 0)
		btn.pressed.connect(_equipar_spawn.bind(index))
		hbox.add_child(btn)
	
	_lista.add_child(panel)

func _equipar_spawn(index: int) -> void:
	if TrailerManager.equipar_trailer(index):
		# Spawn el trailer equipado en el punto de aparición del trailer
		_spawn_trailer_equipado()
		cerrar()

func _spawn_trailer_equipado() -> void:
	var equipado = TrailerManager.get_trailer_equipado()
	if equipado.is_empty():
		return
	
	# Buscar punto de spawn para trailers (cerca del jugador o en punto fijo)
	var spawn_pos = _encontrar_punto_spawn()
	if not spawn_pos:
		print("No hay punto de spawn para trailers")
		return
	
	var trailer_data = TrailerManager.get_trailer_equipado()
	var escena = load(trailer_data["ruta_escena"]) as PackedScene
	if not escena:
		return
	
	var trailer = escena.instantiate()
	trailer.global_transform = spawn_pos
	get_tree().current_scene.add_child(trailer)
	
	# Auto-acoplar si el jugador está cerca y tiene saddle
	_auto_acoplar_si_cerca(trailer)

func _encontrar_punto_spawn() -> Transform3D:
	# Buscar un marcador "TrailerSpawnPoint" en el mapa
	var spawners = get_tree().get_nodes_in_group("trailer_spawn_point")
	if spawners.size() > 0:
		return spawners[0].global_transform
	
	# Fallback: cerca del jugador
	var jugadores = get_tree().get_nodes_in_group("jugador")
	if jugadores.size() > 0:
		var jugador = jugadores[0]
		return jugador.global_transform * Transform3D(Basis.IDENTITY, Vector3(0, 0.5, -6))
	
	return Transform3D.IDENTITY

func _auto_acoplar_si_cerca(trailer: Node) -> void:
	var jugadores = get_tree().get_nodes_in_group("jugador")
	if jugadores.size() == 0:
		return
	
	var jugador = jugadores[0]
	var dist = jugador.global_position.distance_to(trailer.global_position)
	
	if dist < 10.0 and jugador.has_method("puede_acoplar_remolque") and jugador.puede_acoplar_remolque():
		# El jugador tiene saddle add-on, intentar acoplar automáticamente
		call_deferred("_intentar_acople_auto", trailer, jugador)

func _intentar_acople_auto(trailer, jugador) -> void:
	if trailer.has_node("PuntoAcopleRemolque") and jugador.has_node("QuintaRueda"):
		var punto_trailer = trailer.get_node("PuntoAcopleRemolque")
		var punto_jugador = jugador.get_node("QuintaRueda")
		
		var diff = punto_trailer.global_position - punto_jugador.global_position
		jugador.global_position += diff
		
		# Usar el método de acoplar del jugador
		if jugador.has_method("acoplar_remolque_especifico"):
			jugador.acoplar_remolque_especifico(trailer)