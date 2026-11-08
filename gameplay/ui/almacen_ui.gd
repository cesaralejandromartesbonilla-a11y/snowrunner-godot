extends Control

var _lista_garaje: VBoxContainer
var _lista_almacen: VBoxContainer
var _label_info: Label

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
	margen.add_theme_constant_override("margin_top", 30)
	margen.add_theme_constant_override("margin_bottom", 30)
	add_child(margen)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	margen.add_child(vbox)
	
	var titulo = Label.new()
	titulo.text = "ALMACEN DE VEHICULOS"
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.add_theme_font_size_override("font_size", 22)
	vbox.add_child(titulo)
	
	_label_info = Label.new()
	_label_info.text = ""
	_label_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label_info.add_theme_font_size_override("font_size", 14)
	vbox.add_child(_label_info)
	
	vbox.add_child(HSeparator.new())
	
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hbox.custom_minimum_size = Vector2(0, 250)
	vbox.add_child(hbox)
	
	var col_garaje = VBoxContainer.new()
	col_garaje.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(col_garaje)
	
	var lbl_g = Label.new()
	lbl_g.text = "GARAJE (5 slots)"
	lbl_g.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_g.add_theme_font_size_override("font_size", 14)
	col_garaje.add_child(lbl_g)
	
	var scroll_g = ScrollContainer.new()
	scroll_g.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col_garaje.add_child(scroll_g)
	
	_lista_garaje = VBoxContainer.new()
	_lista_garaje.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_lista_garaje.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll_g.add_child(_lista_garaje)
	
	hbox.add_child(VSeparator.new())
	
	var col_almacen = VBoxContainer.new()
	col_almacen.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(col_almacen)
	
	var lbl_a = Label.new()
	lbl_a.text = "ALMACEN"
	lbl_a.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_a.add_theme_font_size_override("font_size", 14)
	col_almacen.add_child(lbl_a)
	
	var scroll_a = ScrollContainer.new()
	scroll_a.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col_almacen.add_child(scroll_a)
	
	_lista_almacen = VBoxContainer.new()
	_lista_almacen.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_lista_almacen.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll_a.add_child(_lista_almacen)
	
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
	if not _lista_garaje or not _lista_almacen:
		return
	for hijo in _lista_garaje.get_children():
		hijo.queue_free()
	for hijo in _lista_almacen.get_children():
		hijo.queue_free()
	
	_cargar_slots_garaje()
	_cargar_almacen()
	_label_info.text = "Almacen: %d vehiculos | Slots: %d/5" % [GlobalData.almacen_vehiculos.size(), _slots_ocupados()]

func _slots_ocupados() -> int:
	var count = 0
	for slot in GlobalData.garaje_slots:
		if slot["ocupado"]:
			count += 1
	return count

func _cargar_slots_garaje() -> void:
	for i in range(5):
		var slot = GlobalData.garaje_slots[i]
		var panel = PanelContainer.new()
		panel.custom_minimum_size = Vector2(0, 50)
		
		var hbox = HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 8)
		panel.add_child(hbox)
		
		var lbl = Label.new()
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		if slot["ocupado"]:
			var nombre = GlobalData._nombre_desde_ruta(slot["ruta_escena"])
			lbl.text = "Slot %d: %s" % [i, nombre]
			hbox.add_child(lbl)
			
			if i != 0:
				var btn_quitar = Button.new()
				btn_quitar.text = "<- Almacen"
				btn_quitar.pressed.connect(_quitar_del_garaje.bind(i))
				hbox.add_child(btn_quitar)
			else:
				var lbl_base = Label.new()
				lbl_base.text = "(Base)"
				lbl_base.modulate = Color(0.5, 0.5, 0.5)
				hbox.add_child(lbl_base)
		else:
			lbl.text = "Slot %d: Vacio" % i
			lbl.modulate = Color(0.5, 0.5, 0.5)
			hbox.add_child(lbl)
			
			if GlobalData.almacen_vehiculos.size() > 0:
				var btn_llenar = Button.new()
				btn_llenar.text = "-> Asignar"
				btn_llenar.pressed.connect(_asignar_al_garaje.bind(i))
				hbox.add_child(btn_llenar)
		
		_lista_garaje.add_child(panel)

func _cargar_almacen() -> void:
	if GlobalData.almacen_vehiculos.is_empty():
		var lbl = Label.new()
		lbl.text = "Sin vehiculos almacenados"
		lbl.modulate = Color(0.5, 0.5, 0.5)
		_lista_almacen.add_child(lbl)
		return
	
	for i in range(GlobalData.almacen_vehiculos.size()):
		var v = GlobalData.almacen_vehiculos[i]
		var panel = PanelContainer.new()
		panel.custom_minimum_size = Vector2(0, 50)
		
		var hbox = HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 8)
		panel.add_child(hbox)
		
		var lbl = Label.new()
		lbl.text = v.get("nombre", "Sin nombre")
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(lbl)
		
		var slot_vacio = _buscar_slot_vacio()
		if slot_vacio != -1:
			var btn_asignar = Button.new()
			btn_asignar.text = "-> Slot %d" % slot_vacio
			btn_asignar.pressed.connect(_asignar_directo.bind(i, slot_vacio))
			hbox.add_child(btn_asignar)
		else:
			var lbl_lleno = Label.new()
			lbl_lleno.text = "(Garaje lleno)"
			lbl_lleno.modulate = Color(1, 0.3, 0.3)
			hbox.add_child(lbl_lleno)
		
		_lista_almacen.add_child(panel)

func _buscar_slot_vacio() -> int:
	for i in range(5):
		if not GlobalData.garaje_slots[i]["ocupado"]:
			return i
	return -1

func _asignar_al_garaje(slot_index: int) -> void:
	if GlobalData.almacen_vehiculos.size() > 0:
		GlobalData.mover_a_garaje(0, slot_index)
		_refrescar()

func _asignar_directo(almacen_index: int, slot_index: int) -> void:
	GlobalData.mover_a_garaje(almacen_index, slot_index)
	_refrescar()

func _quitar_del_garaje(slot_index: int) -> void:
	GlobalData.mover_a_almacen(slot_index)
	_refrescar()
