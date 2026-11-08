extends Control

var _lista: VBoxContainer
var _label_dinero: Label

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
	titulo.text = "SELECCIONAR MAPA"
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.add_theme_font_size_override("font_size", 22)
	vbox.add_child(titulo)
	
	_label_dinero = Label.new()
	_label_dinero.text = "Dinero: $%d" % GlobalData.dinero
	_label_dinero.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label_dinero.add_theme_font_size_override("font_size", 14)
	vbox.add_child(_label_dinero)
	
	vbox.add_child(HSeparator.new())
	
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size = Vector2(0, 300)
	vbox.add_child(scroll)
	
	_lista = VBoxContainer.new()
	_lista.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_lista.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.add_child(_lista)
	
	var btn_cerrar = Button.new()
	btn_cerrar.text = "Cerrar"
	btn_cerrar.custom_minimum_size = Vector2(0, 40)
	btn_cerrar.pressed.connect(cerrar)
	vbox.add_child(btn_cerrar)

func abrir() -> void:
	show()
	_refrescar()

func cerrar() -> void:
	hide()
	var garaje = get_parent().get_parent()
	if garaje and garaje.has_method("_recargar_vehiculos"):
		garaje._recargar_vehiculos()

func _refrescar() -> void:
	if not _lista:
		return
	for hijo in _lista.get_children():
		hijo.queue_free()
	
	_label_dinero.text = "Dinero: $%d" % GlobalData.dinero
	
	for entry in _get_mapas():
		_crear_tarjeta(entry)

func _get_mapas() -> Array:
	return [
		{
			"id": "rio_negro",
			"nombre": "Río Negro (Black River)",
			"region": "Michigan, USA",
			"dificultad": "Fácil-Media",
			"terreno": "Barro, asfalto, colinas",
			"descripcion": "Mapa inicial. Ideal para el CK1500 y Fleetstar.",
			"ruta": "res://gameplay/maps/rio_negro.tscn",
			"requiere_vehiculo": ""
		},
		{
			"id": "alaska",
			"nombre": "Alaska",
			"region": "Alaska, USA",
			"dificultad": "Media",
			"terreno": "Nieve, hielo, montaña",
			"descripcion": "Requiere neumáticos de nieve y AWD. Desbloquea al completar 2 contratos.",
			"ruta": "res://gameplay/maps/alaska.tscn",
			"requiere_vehiculo": "awd"
		},
		{
			"id": "taymyr",
			"nombre": "Taymyr",
			"region": "Siberia, Rusia",
			"dificultad": "Difícil",
			"terreno": "Pantano denso, raíces, bosque",
			"descripcion": "Solo para vehículos pesados con diff lock. Desbloquea al completar Alaska.",
			"ruta": "res://gameplay/maps/taymyr.tscn",
			"requiere_vehiculo": "heavy"
		}
	]

func _crear_tarjeta(entry: Dictionary) -> void:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 140)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	panel.add_child(vbox)
	
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	vbox.add_child(hbox)
	
	var info = VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(info)
	
	var lbl_nombre = Label.new()
	lbl_nombre.text = entry["nombre"] + "  [" + entry["region"] + "]"
	lbl_nombre.add_theme_font_size_override("font_size", 16)
	info.add_child(lbl_nombre)
	
	var lbl_stats = Label.new()
	lbl_stats.text = "Dificultad: %s  |  Terreno: %s" % [entry["dificultad"], entry["terreno"]]
	lbl_stats.add_theme_font_size_override("font_size", 12)
	info.add_child(lbl_stats)
	
	var lbl_desc = Label.new()
	lbl_desc.text = entry["descripcion"]
	lbl_desc.add_theme_font_size_override("font_size", 11)
	lbl_desc.modulate = Color(0.7, 0.7, 0.7)
	info.add_child(lbl_desc)
	
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(140, 0)
	
	var disponible = _mapa_disponible(entry)
	if disponible:
		btn.text = "Viajar"
		btn.pressed.connect(_viajar.bind(entry["ruta"]))
	elif entry["requiere_vehiculo"] == "awd":
		btn.text = "Requiere AWD"
		btn.disabled = true
	elif entry["requiere_vehiculo"] == "heavy":
		btn.text = "Requiere camión pesado"
		btn.disabled = true
	else:
		btn.text = "Bloqueado"
		btn.disabled = true
	
	hbox.add_child(btn)
	_lista.add_child(panel)

func _mapa_disponible(entry: Dictionary) -> bool:
	if entry["id"] == "rio_negro":
		return true
	if entry["id"] == "alaska":
		# Desbloquea si tienes dinero >= 500 (simula progresión)
		return GlobalData.dinero >= 500
	if entry["id"] == "taymyr":
		return GlobalData.dinero >= 1500
	return false

func _viajar(ruta: String) -> void:
	var manager = get_parent().get_parent()
	if manager:
		GlobalData.guardar_partida(ruta)
		get_tree().change_scene_to_file(ruta)
