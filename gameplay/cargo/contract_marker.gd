extends Node3D

@export var contrato_id: String = ""
@export var carga_nombre: String = "Suministros"
@export var usar_como_pickup: bool = true

var jugador_en_zona: bool = false
var mesh_instancia: MeshInstance3D

func _ready() -> void:
	add_to_group("contract_pickups")
	_crear_visual()
	setup_area()

func _crear_visual() -> void:
	mesh_instancia = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(2, 1, 2)
	mesh_instancia.mesh = box
	add_child(mesh_instancia)

func _process(_delta: float) -> void:
	if jugador_en_zona and Input.is_action_just_pressed("press_f"):
		_interactuar()

func _interactuar() -> void:
	var contrato_activo = ContratoManager.get_contrato_activo()
	if not contrato_activo:
		print("Sin contrato activo. Acude a una tabla de contratos.")
		return
	
	if contrato_activo.id != contrato_id:
		print("Este punto no es para tu contrato actual.")
		return
	
	if usar_como_pickup:
		if contrato_activo.estado == ContratoData.EstadoContrato.ACEPTADO:
			ContratoManager.recoger_carga()
			var vehiculo = _encontrar_jugador()
			if vehiculo and vehiculo.has_method("recibir_carga"):
				vehiculo.recibir_carga()
			print("Carga recogida: ", carga_nombre)
		else:
			print("Ya recogiste esta carga o el contrato no esta en estado correcto.")
	else:
		if contrato_activo.estado == ContratoData.EstadoContrato.CARGA_RECOGIDA:
			var recompensa = ContratoManager.entregar_carga()
			var vehiculo = _encontrar_jugador()
			if vehiculo and vehiculo.has_method("entregar_carga"):
				vehiculo.entregar_carga()
			GlobalData.dinero += recompensa
			print("Contrato completado! +$%d" % recompensa)

func _encontrar_jugador() -> Node3D:
	var jugadores = get_tree().get_nodes_in_group("jugador")
	if jugadores.size() > 0:
		return jugadores[0]
	return null

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("jugador"):
		jugador_en_zona = true

func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("jugador"):
		jugador_en_zona = false

func setup_area() -> void:
	var area = Area3D.new()
	area.name = "InteractArea"
	var shape = BoxShape3D.new()
	shape.size = Vector3(4, 3, 4)
	var col = CollisionShape3D.new()
	col.shape = shape
	area.add_child(col)
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)
	add_child(area)
