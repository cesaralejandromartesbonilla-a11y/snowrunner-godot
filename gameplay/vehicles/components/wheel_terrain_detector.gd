class_name WheelTerrainDetector
extends RayCast3D

var wheel: VehicleWheel3D
var terreno_actual: String = "desconocido"
var friccion_terreno: float = 0.8

func _init() -> void:
	target_position = Vector3(0, -0.5, 0)
	collide_with_areas = true
	collide_with_bodies = true

func setup(p_wheel: VehicleWheel3D) -> void:
	wheel = p_wheel
	target_position = Vector3(0, -(wheel.wheel_radius + 0.1), 0)

func _physics_process(_delta: float) -> void:
	if not is_colliding():
		terreno_actual = "desconocido"
		friccion_terreno = 0.8
		return
	
	var collider = get_collider()
	terreno_actual = _detectar_terreno(collider)
	friccion_terreno = TerrainManager.get_friccion(terreno_actual)

func _detectar_terreno(collider: Node) -> String:
	if collider is Area3D and "terrain_type" in collider:
		return collider.terrain_type
	
	if collider is StaticBody3D:
		for group in ["barro_ligero", "barro_estandar", "barro_profundo", "barro_extremo"]:
			if collider.is_in_group(group):
				return group
	
	return "tierra"
