class_name AddOnData
extends Resource

enum TipoAddOn { SADDLE, FLATBED, LOG_CARRIER, CRANE, FUEL_TANK, WINCH, SNORKEL }

@export var nombre: String = "Add-on"
@export var tipo: TipoAddOn = TipoAddOn.SADDLE
@export var descripcion: String = ""
@export var peso: float = 100.0
@export var precio: int = 500
@export var slot_requerido: String = "frame"  # frame, roof, saddle, front, rear
@export var capacidad_carga_extra: float = 0.0
@export var fuel_extra: float = 0.0
@export var permite_remolque: bool = false
@export var permite_autocarga: bool = false
