extends Area3D

@export var mapa_destino: String = ""
@export var nombre_gateway: String = "Gateway"
@export var region: String = ""
@export var requiere_dinero: int = 0

var jugador_en_zona: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_crear_visual()

func _crear_visual() -> void:
	var mesh = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(6, 4, 6)
	mesh.mesh = box
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.8, 0.2, 1)
	mat.emission_enabled = true
	mat.emission = Color(0.2, 1, 0.2, 1)
	mat.emission_energy_multiplier = 0.5
	mesh.material_override = mat
	
	add_child(mesh)
	
	# Texto flotante
	var label = Label3D.new()
	label.text = nombre_gateway + " → " + mapa_destino
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.font_size = 12
	label.translate(Vector3(0, 3, 0))
	add_child(label)

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("jugador"):
		jugador_en_zona = true

func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("jugador"):
		jugador_en_zona = false

func _unhandled_input(event: InputEvent) -> void:
	if not jugador_en_zona:
		return
	if event.is_action_pressed("press_f"):
		_interactuar()

func _interactuar() -> void:
	if GlobalData.dinero < requiere_dinero:
		print("Necesitas $%d para usar este gateway." % requiere_dinero)
		return
	
	if mapa_destino == "":
		print("Gateway sin destino configurado.")
		return
	
	print("Viajando a %s..." % mapa_destino)
	GlobalData.dinero -= requiere_dinero
	GlobalData.guardar_partida(mapa_destino)
	get_tree().change_scene_to_file(mapa_destino)
