class_name VehicleStats
extends Resource

@export var nombre: String = "Vehiculo"
@export var masa: float = 3000.0
@export var combustible_max: float = 200.0
@export var consumo_base: float = 0.5

@export_group("Transmision")
enum AWDMode { NONE, SWITCHABLE, ALWAYS_ON }
enum DiffMode { NONE, SWITCHABLE, ALWAYS_ON }
@export var awd_mode: AWDMode = AWDMode.SWITCHABLE
@export var diff_mode: DiffMode = DiffMode.SWITCHABLE

@export_group("Motor")
@export var max_torque: float = 600.0
@export var max_rpm: float = 3000.0
@export var curva_torque: Curve

@export_group("Caja de Cambios")
@export var ratios: PackedFloat32Array = PackedFloat32Array([4.8, 2.5, 1.6, 1.0, 0.7])  # Low, 1, 2, 3, 4
@export var ratio_reversa: float = 3.5
@export var ratio_diferencial: float = 3.7
@export var rpm_min: float = 800.0

@export_group("Direccion")
@export var steering_max: float = 0.6
@export var steering_speed: float = 2.5

@export_group("Ruedas")
@export var tire_size: float = 42.0
@export var ground_clearance: float = 0.4
@export var friction_slip_base: float = 2.0
@export var friction_slip_diff: float = 5.0

func _init() -> void:
	if not curva_torque:
		curva_torque = Curve.new()
		curva_torque.add_point(Vector2(0, 0.2))
		curva_torque.add_point(Vector2(0.3, 1.0))
		curva_torque.add_point(Vector2(0.7, 0.9))
		curva_torque.add_point(Vector2(1.0, 0.3))

func get_gear_name(gear_index: int) -> String:
	match gear_index:
		-3: return "R"
		-2: return "N"
		-1: return "L"
		0: return "1"
		1: return "2"
		2: return "3"
		3: return "4"
		_: return "?"

func get_gear_count() -> int:
	return ratios.size()
