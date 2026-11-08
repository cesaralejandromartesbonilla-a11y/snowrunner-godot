extends Area3D

@export var torre_id: String = ""
@export var radio_revelado: float = 500.0
@export var recompensa: int = 50

var jugador_en_zona: bool = false
var activada: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_crear_visual()

func _crear_visual() -> void:
	# Torre (cilindro alto)
	var mesh = MeshInstance3D.new()
	var cyl = CylinderMesh.new()
	cyl.top_radius = 1.5
	cyl.bottom_radius = 2.5
	cyl.height = 15.0
	mesh.mesh = cyl
	
	var mat = StandardMaterial3D.new()
	if activada:
		mat.albedo_color = Color(0.2, 0.8, 0.2, 1)
		mat.emission_enabled = true
		mat.emission = Color(0.2, 1, 0.2, 1)
		mat.emission_energy_multiplier = 1.0
	else:
		mat.albedo_color = Color(0.4, 0.4, 0.4, 1)
	mat.roughness = 0.8
	mesh.material_override = mat
	
	mesh.translate(Vector3(0, 7.5, 0))
	add_child(mesh)
	
	# Plataforma superior
	var platform = MeshInstance3D.new()
	var plat_mesh = CylinderMesh.new()
	plat_mesh.top_radius = 3.0
	plat_mesh.bottom_radius = 3.0
	plat_mesh.height = 1.0
	platform.mesh = plat_mesh
	platform.material_override = mat
	platform.translate(Vector3(0, 15.5, 0))
	add_child(platform)
	
	# Zona de activación (esfera invisible arriba)
	var area_act = Area3D.new()
	area_act.name = "ActivationArea"
	var sphere = SphereShape3D.new()
	sphere.radius = 3.0
	var col = CollisionShape3D.new()
	col.shape = sphere
	col.position = Vector3(0, 15.5, 0)
	area_act.add_child(col)
	area_act.body_entered.connect(_on_activation_entered)
	area_act.body_exited.connect(_on_activation_exited)
	add_child(area_act)

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("jugador"):
		jugador_en_zona = true

func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("jugador"):
		jugador_en_zona = false

func _on_activation_entered(body: Node3D) -> void:
	if body.is_in_group("jugador") and not activada:
		print("Presiona F en la cima de la torre para activar.")

func _on_activation_exited(body: Node3D) -> void:
	pass

func _unhandled_input(event: InputEvent) -> void:
	if not jugador_en_zona or activada:
		return
	if event.is_action_pressed("press_f"):
		_activar()

func _activar() -> void:
	activada = true
	GlobalData.dinero += recompensa
	print("Torre %s activada! +$%d. Área revelada: %.0fm" % [torre_id, recompensa, radio_revelado])
	
	# Cambiar color visual
	for child in get_children():
		if child is MeshInstance3D:
			if child.material_override:
				var mat = child.material_override.duplicate()
				mat.albedo_color = Color(0.2, 0.8, 0.2, 1)
				mat.emission_enabled = true
				mat.emission = Color(0.2, 1, 0.2, 1)
				mat.emission_energy_multiplier = 1.0
				child.material_override = mat
	
	# Aquí se podría disparar señal para revelar niebla de guerra en UI de mapa
	emit_signal("torre_activada", torre_id, global_position, radio_revelado)

signal torre_activada(torre_id: String, posicion: Vector3, radio: float)
