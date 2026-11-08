class_name CargoData
extends Resource

enum TipoCarga { ESTANDAR, MADERA, LIQUIDO, GASOLINA, REPARACION }

@export var nombre: String = "Carga"
@export var tipo: TipoCarga = TipoCarga.ESTANDAR
@export var peso: float = 500.0
@export var valor_venta: int = 100
@export var slots_ocupados: int = 1
