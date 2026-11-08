extends Control

var _lista: VBoxContainer
var _label_dinero: Label
var _label_patio: Label

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
	titulo.text = "PATIO DE REMOLQUES"
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.add_theme_font_size_override("font_size", 22)
	vbox.add_child(titulo)
	
	var hbox_info = HBoxContainer.new()
	hbox_info.add_theme_constant_override("separation", 20)
	vbox.add_child(hbox_info)
	
	_label_dinero = Label.new()
	_label_dinero.text = "Dinero: $%d" % GlobalData.dinero
	_label_dinero.add_theme_font_size_override("font_size", 14)
	hbox_info.add_child(_label_dinero)
	
	_label_patio = Label.new()
	_label_patio.text = "Patio: %d remolques" % TrailerManager.get_trailers_propios().size()
	_label_patio.add_theme_font_size_override("font_size", 14)
	hbox_info.add_child(_label_patio)
	
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
	_label_patio.text = "Patio: %d remolques" % TrailerManager.get_trailers_propios().size()
	
	# Sección: Comprar remolques
	var lbl_comprar = Label.new()
	lbl_comprar.text = "=== DISPONIBLES PARA COMPRAR ==="
	lbl_comprar.add_theme_font_size_override("font_size", 14)
	lbl_comprar.modulate = Color(0.7, 1, 0.7)
	_lista.add_child(lbl_comprar)
	
	for entry in TrailerManager.get_trailers_disponibles():
		if not TrailerManager.ya_tiene_trailer(entry.ruta_escena):
			_crear_tarjeta_compra(entry)
	
	# Separador
	var lbl_patio = Label.new()
	lbl_patio.text = "=== TU PATIO ==="
	lbl_patio.add_theme_font_size_override("font_size", 14)
	lbl_patio.modulate = Color(0.7, 0.9, 1)
	_lista.add_child(lbl_patio)
	
	var propios = TrailerManager.get_trailers_propios()
	if propios.is_empty():
		var lbl_vacio = Label.new()
		lbl_vacio.text = "Patio vacío - compra remolques en la tienda"
		lbl_vacio.modulate = Color(0.5, 0.5, 0.5)
		_lista.add_child(lbl_vacio)
	else:
		for i in range(propios.size()):
			_crear_tarjeta_patio(propios[i], i)

func _crear_tarjeta_compra(entry: TrailerData) -> void:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 100)
	
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
	lbl_nombre.text = entry.nombre
	lbl_nombre.add_theme_font_size_override("font_size", 16)
	info.add_child(lbl_nombre)
	
	var lbl_stats = Label.new()
	lbl_stats.text = "Masa: %.0fkg | Capacidad: %.0fkg | Slots: %d" % [entry.masa, entry.capacidad_carga, entry.slots_carga]
	lbl_stats.add_theme_font_size_override("font_size", 12)
	info.add_child(lbl_stats)
	
	var lbl_desc = Label.new()
	lbl_desc.text = entry.descripcion
	lbl_desc.add_theme_font_size_override("font_size", 11)
	lbl_desc.modulate = Color(0.7, 0.7, 0.7)
	info.add_child(lbl_desc)
	
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(120, 0)
	
	if GlobalData.dinero < entry.precio:
		btn.text = "$%d" % entry.precio
		btn.disabled = true
		btn.tooltip_text = "Necesitas $%d" % entry.precio
	else:
		btn.text = "$%d" % entry.precio
		btn.pressed.connect(_comprar.bind(entry.ruta_escena))
	
	hbox.add_child(btn)
	_lista.add_child(panel)

func _crear_tarjeta_patio(trailer: Dictionary, index: int) -> void:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 80)
	
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	panel.add_child(hbox)
	
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
		var btn = Button.new()
		btn.text = "Equipado ✓"
		btn.disabled = true
		hbox.add_child(btn)
	else:
		var btn = Button.new()
		btn.text = "Equipar"
		btn.custom_minimum_size = Vector2(100, 0)
		btn.pressed.connect(_equipar.bind(index))
		hbox.add_child(btn)
	
	var btn_vender = Button.new()
	btn_vender.text = "Vender"
	btn_vender.custom_minimum_size = Vector2(80, 0)
	btn_vender.modulate = Color(1, 0.5, 0.5)
	btn_vender.pressed.connect(_vender.bind(index))
	hbox.add_child(btn_vender)
	
	_lista.add_child(panel)

func _comprar(ruta: String) -> void:
	for entry in TrailerManager.get_trailers_disponibles():
		if entry.ruta_escena == ruta:
			if TrailerManager.comprar_trailer(entry.ruta_escena):
				_refrescar()
			break

func _equipar(index: int) -> void:
	if TrailerManager.equipar_trailer(index):
		_refrescar()

func _vender(index: int) -> void:
	var propios = TrailerManager.get_trailers_propios()
	if index < 0 or index >= propios.size():
		return
	
	var trailer = propios[index]
	var precio_venta = (TrailerManager.get_trailer_data(trailer["ruta_escena"]).precio * 0.5) as int
	GlobalData.dinero += precio_venta
	
	# Si estaba equipado, desequipar
	if TrailerManager.trailer_equipado_actual == trailer["ruta_escena"]:
		TrailerManager.desequipar_trailer()
	
	TrailerManager.trailers_propios.remove_at(index)
	print("Vendido: ", trailer["nombre"], " por $", precio_venta)
	_refrescar()