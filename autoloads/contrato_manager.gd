extends Node

signal contrato_aceptado(nombre: String)
signal carga_recogida(nombre: String)
signal contrato_completado(nombre: String, recompensa: int)

var contrato_activo: ContratoData = null
var contratos_disponibles: Array = []

func _ready() -> void:
	_inicializar_contratos()

func _inicializar_contratos() -> void:
	contratos_disponibles.clear()
	
	var c1 = ContratoData.new()
	c1.id = "rn_01"
	c1.nombre = "Suministros al Garage"
	c1.descripcion = "Recoge suministros y entrega en el garage."
	c1.recompensa = 150
	c1.nombre_carga = "Suministros"
	c1.mapa = "rio_negro"
	contratos_disponibles.append(c1)
	
	var c2 = ContratoData.new()
	c2.id = "rn_02"
	c2.nombre = "Materiales de Construccion"
	c2.descripcion = "Transporta troncos desde el bosque hasta la zona de entrega."
	c2.recompensa = 300
	c2.nombre_carga = "Troncos"
	c2.mapa = "rio_negro"
	contratos_disponibles.append(c2)
	
	var c3 = ContratoData.new()
	c3.id = "rn_03"
	c3.nombre = "Combustible de Emergencia"
	c3.descripcion = "Entrega combustible a la estacion remota."
	c3.recompensa = 200
	c3.nombre_carga = "Combustible"
	c3.mapa = "rio_negro"
	contratos_disponibles.append(c3)
	
	var c4 = ContratoData.new()
	c4.id = "rn_04"
	c4.nombre = "Repuestos Criticos"
	c4.descripcion = "Transporta repuestos delicados sin volcar."
	c4.recompensa = 400
	c4.nombre_carga = "Repuestos"
	c4.mapa = "rio_negro"
	contratos_disponibles.append(c4)
	
	# ALASKA
	var c5 = ContratoData.new()
	c5.id = "ak_01"
	c5.nombre = "Suministros Polares"
	c5.descripcion = "Entrega suministros a la base en la montaña."
	c5.recompensa = 500
	c5.nombre_carga = "Suministros"
	c5.mapa = "alaska"
	contratos_disponibles.append(c5)
	
	var c6 = ContratoData.new()
	c6.id = "ak_02"
	c6.nombre = "Equipo Cientifico"
	c6.descripcion = "Transporta equipo delicado a la estacion de investigacion."
	c6.recompensa = 700
	c6.nombre_carga = "Repuestos"
	c6.mapa = "alaska"
	contratos_disponibles.append(c6)
	
	# TAYMYR
	var c7 = ContratoData.new()
	c7.id = "ty_01"
	c7.nombre = "Maquinaria Pesada"
	c7.descripcion = "Mueve excavadoras al campamento minero."
	c7.recompensa = 1000
	c7.nombre_carga = "Troncos"
	c7.mapa = "taymyr"
	contratos_disponibles.append(c7)
	
	var c8 = ContratoData.new()
	c8.id = "ty_02"
	c8.nombre = "Combustible de Emergencia"
	c8.descripcion = "Entrega bidones de combustible al pueblo remoto."
	c8.recompensa = 1200
	c8.nombre_carga = "Combustible"
	c8.mapa = "taymyr"
	contratos_disponibles.append(c8)

func aceptar_contrato(contrato: ContratoData) -> void:
	if contrato_activo:
		return
	contrato_activo = contrato
	contrato_activo.estado = ContratoData.EstadoContrato.ACEPTADO
	contrato_aceptado.emit(contrato.nombre)

func recoger_carga() -> void:
	if contrato_activo and contrato_activo.estado == ContratoData.EstadoContrato.ACEPTADO:
		contrato_activo.estado = ContratoData.EstadoContrato.CARGA_RECOGIDA
		carga_recogida.emit(contrato_activo.nombre_carga)

func entregar_carga() -> int:
	if contrato_activo and contrato_activo.estado == ContratoData.EstadoContrato.CARGA_RECOGIDA:
		contrato_activo.estado = ContratoData.EstadoContrato.ENTREGADO
		var recompensa = contrato_activo.recompensa
		contrato_completado.emit(contrato_activo.nombre, recompensa)
		contrato_activo = null
		return recompensa
	return 0

func cancelar_contrato() -> void:
	if contrato_activo:
		contrato_activo.estado = ContratoData.EstadoContrato.DISPONIBLE
		contrato_activo = null

func get_contrato_activo() -> ContratoData:
	return contrato_activo

func get_contratos_por_mapa(mapa: String) -> Array:
	var resultado = []
	for c in contratos_disponibles:
		if c.mapa == mapa and c.estado == ContratoData.EstadoContrato.DISPONIBLE:
			resultado.append(c)
	return resultado
