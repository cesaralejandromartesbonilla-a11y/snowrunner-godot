extends Node

@onready var punto_aparicion = $PuntoAparicion

const CONTRACT_HUD = preload("res://gameplay/ui/contract_hud.gd")
const TRAILER_SPAWNER_HUD = preload("res://gameplay/ui/trailer_spawner_hud.gd")

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	var datos_vehiculo = GlobalData.obtener_datos_vehiculo_activo()
	
	if datos_vehiculo["ruta_escena"] != "":
		var escena = load(datos_vehiculo["ruta_escena"]) as PackedScene
		if escena:
			var vehiculo = escena.instantiate()
			vehiculo.global_transform = punto_aparicion.global_transform
			add_child(vehiculo)
			vehiculo.process_mode = Node.PROCESS_MODE_INHERIT
	
	var hud = CanvasLayer.new()
	hud.name = "ContractHUD"
	hud.set_script(CONTRACT_HUD)
	add_child(hud)
	
	var trailer_hud = CanvasLayer.new()
	trailer_hud.name = "TrailerSpawnerHUD"
	trailer_hud.set_script(TRAILER_SPAWNER_HUD)
	add_child(trailer_hud)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("press_y"):  # Tecla Y para abrir selector de trailers
		var hud = get_node_or_null("TrailerSpawnerHUD")
		if hud and hud.has_method("abrir"):
			hud.abrir()
