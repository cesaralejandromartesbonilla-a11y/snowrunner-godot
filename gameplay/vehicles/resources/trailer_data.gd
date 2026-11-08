class_name TrailerData
extends Resource

enum TipoRemolque { BASICO, CARGA, CARGA_LARGA, CISTERNA, GRUA, REPARACION }

@export var nombre: String = "Remolque"
@export var tipo: TipoRemolque = TipoRemolque.BASICO
@export var descripcion: String = ""
@export var precio: int = 1000
@export var masa: float = 2000.0
@export var capacidad_carga: float = 0.0
@export var slots_carga: int = 0
@export var requiere_saddle: bool = true
@export var ruta_escena: String = ""
@export var center_of_mass: Vector3 = Vector3(0, 0.5, 0)