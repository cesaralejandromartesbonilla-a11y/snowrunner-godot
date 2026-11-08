class_name ContratoData
extends Resource

enum EstadoContrato { DISPONIBLE, ACEPTADO, CARGA_RECOGIDA, ENTREGADO }

@export var id: String = ""
@export var nombre: String = "Contrato"
@export var descripcion: String = ""
@export var recompensa: int = 100
@export var nombre_carga: String = "Suministros"
@export var ruta_carga: String = ""
@export var ruta_entrega: String = ""
@export var mapa: String = ""
@export var estado: EstadoContrato = EstadoContrato.DISPONIBLE
