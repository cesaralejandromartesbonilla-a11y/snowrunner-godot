# Admisión de aspiración natural — la más simple. A diferencia de un turbo
# (otro tipo de admisión, diferido a propósito, ver hoja de ruta), el techo
# de eficiencia acá no varía con RPM ni con presión de sobrealimentación.
# eficiencia_admision es un multiplicador de tamaño: misma curva_potencia
# de Motor (la forma, cómo respira en cada RPM) sirve para cualquier motor —
# solo cambia este número (la magnitud) entre un motor chico y uno grande.
extends Resource
class_name Admision

@export var eficiencia_admision: float = 1.0  # 1.0 = referencia; motores más grandes = más alto
