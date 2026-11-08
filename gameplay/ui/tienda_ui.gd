extends Control

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
	titulo.text = "TIENDA DE VEHICULOS"
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

var _label_dinero: Label
var _lista: VBoxContainer

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
	
	for entry in GlobalData.CATALOGO_VEHICULOS:
		_crear_tarjeta(entry)

func _crear_tarjeta(entry: Dictionary) -> void:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 100)
	
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	panel.add_child(hbox)
	
	var info = VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(info)
	
	var lbl_nombre = Label.new()
	lbl_nombre.text = entry["nombre"] + "  [" + entry["clase"] + "]"
	lbl_nombre.add_theme_font_size_override("font_size", 16)
	info.add_child(lbl_nombre)
	
	var lbl_stats = Label.new()
	lbl_stats.text = "AWD: %s  |  Diff: %s  |  Masa: %s  |  Fuel: %s" % [entry["awd"], entry["diff"], entry["masa"], entry["fuel"]]
	lbl_stats.add_theme_font_size_override("font_size", 12)
	info.add_child(lbl_stats)
	
	var lbl_desc = Label.new()
	lbl_desc.text = entry["descripcion"]
	lbl_desc.add_theme_font_size_override("font_size", 11)
	lbl_desc.modulate = Color(0.7, 0.7, 0.7)
	info.add_child(lbl_desc)
	
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(120, 0)
	
	if GlobalData.ya_comprado(entry["id"]):
		btn.text = "Comprado"
		btn.disabled = true
	elif entry["precio"] == 0:
		btn.text = "Gratis"
		btn.pressed.connect(_comprar.bind(entry))
	elif GlobalData.dinero < entry["precio"]:
		btn.text = "$%d" % entry["precio"]
		btn.disabled = true
		btn.tooltip_text = "Necesitas $%d" % entry["precio"]
	else:
		btn.text = "$%d" % entry["precio"]
		btn.pressed.connect(_comprar.bind(entry))
	
	hbox.add_child(btn)
	_lista.add_child(panel)

func _comprar(entry: Dictionary) -> void:
	if GlobalData.comprar_vehiculo(entry):
		_refrescar()
