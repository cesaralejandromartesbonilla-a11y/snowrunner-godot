extends Area3D

@export var contratos_ids: Array[String] = []
var jugador_en_zona: bool = false
var contrato_seleccionado: int = 0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("jugador"):
		jugador_en_zona = true
		_mostrar_contratos()

func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("jugador"):
		jugador_en_zona = false

func _mostrar_contratos() -> void:
	var disponibles = []
	for cid in contratos_ids:
		for c in ContratoManager.contratos_disponibles:
			if c.id == cid and c.estado == ContratoData.EstadoContrato.DISPONIBLE:
				disponibles.append(c)
	
	if disponibles.is_empty():
		print("Sin contratos disponibles en esta tabla.")
		return
	
	if ContratoManager.get_contrato_activo():
		print("Ya tienes un contrato activo. Complete o cancelelo primero.")
		return
	
	for c in disponibles:
		print("[%s] %s - $%d" % [c.id, c.nombre, c.recompensa])
	print("Presiona F de nuevo para aceptar el primero de la lista.")
	_contratos_listados = disponibles

var _contratos_listados: Array = []

func _unhandled_input(event: InputEvent) -> void:
	if not jugador_en_zona:
		return
	if event.is_action_pressed("press_f") and _contratos_listados.size() > 0:
		if ContratoManager.get_contrato_activo():
			print("Ya tienes un contrato activo.")
			return
		var contrato = _contratos_listados[0]
		ContratoManager.aceptar_contrato(contrato)
		print("Contrato aceptado: ", contrato.nombre)
		print("Recoge la carga y entrega en el destino.")
		_contratos_listados.clear()
