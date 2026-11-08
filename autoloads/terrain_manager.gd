extends Node

const TIPOS_TERRENO: Dictionary = {
	"desconocido": {"friccion": 0.8, "resistencia": 0.0, "profundidad": 0.0, "es_liquido": false, "dano_agua": 0.0},
	"asfalto":     {"friccion": 1.0, "resistencia": 0.0, "profundidad": 0.0, "es_liquido": false, "dano_agua": 0.0},
	"tierra":      {"friccion": 0.65, "resistencia": 0.3, "profundidad": 0.1, "es_liquido": false, "dano_agua": 0.0},
	"barro_ligero":  {"friccion": 0.35, "resistencia": 1.5, "profundidad": 0.3, "es_liquido": false, "dano_agua": 0.0},
	"barro_estandar": {"friccion": 0.2, "resistencia": 4.0, "profundidad": 0.5, "es_liquido": false, "dano_agua": 0.0},
	"barro_profundo": {"friccion": 0.1, "resistencia": 8.0, "profundidad": 0.8, "es_liquido": false, "dano_agua": 0.0},
	"barro_extremo":  {"friccion": 0.05, "resistencia": 15.0, "profundidad": 1.2, "es_liquido": false, "dano_agua": 0.0},
	"nieve":        {"friccion": 0.3, "resistencia": 0.5, "profundidad": 0.2, "es_liquido": false, "dano_agua": 0.0},
	"nieve_profunda": {"friccion": 0.15, "resistencia": 3.0, "profundidad": 0.6, "es_liquido": false, "dano_agua": 0.0},
	"hielo":        {"friccion": 0.05, "resistencia": 0.0, "profundidad": 0.0, "es_liquido": false, "dano_agua": 0.0},
	"agua_poco":    {"friccion": 0.3, "resistencia": 2.0, "profundidad": 0.4, "es_liquido": true, "dano_agua": 0.5},
	"agua_media":   {"friccion": 0.15, "resistencia": 5.0, "profundidad": 0.8, "es_liquido": true, "dano_agua": 2.0},
	"agua_profunda": {"friccion": 0.05, "resistencia": 10.0, "profundidad": 1.5, "es_liquido": true, "dano_agua": 8.0},
	"roca":         {"friccion": 0.9, "resistencia": 0.0, "profundidad": 0.0, "es_liquido": false, "dano_agua": 0.0},
}

var zonas_activas: Array[Area3D] = []

func get_tipo_en_pos(pos: Vector3) -> String:
	var mejor_zona: Area3D = null
	var mejor_dist: float = INF
	
	for zona in zonas_activas:
		if zona.overlaps_point(pos):
			var dist = pos.distance_to(zona.global_position)
			if dist < mejor_dist:
				mejor_dist = dist
				mejor_zona = zona
	
	if mejor_zona and mejor_zona.terrain_type in TIPOS_TERRENO:
		return mejor_zona.terrain_type
	return "desconocido"

func get_datos(tipo: String) -> Dictionary:
	if tipo in TIPOS_TERRENO:
		return TIPOS_TERRENO[tipo]
	return TIPOS_TERRENO["desconocido"]

func get_friccion(tipo: String) -> float:
	return get_datos(tipo)["friccion"]

func get_resistencia(tipo: String) -> float:
	return get_datos(tipo)["resistencia"]

func get_profundidad(tipo: String) -> float:
	return get_datos(tipo)["profundidad"]

func es_liquido(tipo: String) -> bool:
	return get_datos(tipo)["es_liquido"]

func get_dano_agua(tipo: String) -> float:
	return get_datos(tipo)["dano_agua"]

func registrar_zona(zona: Area3D) -> void:
	if zona not in zonas_activas:
		zonas_activas.append(zona)

func deregistrar_zona(zona: Area3D) -> void:
	zonas_activas.erase(zona)
