extends Node
class_name ClimateService

var data: Dictionary = {}
var display_to_key := {
    "CORDOBA":      "Cordoba_AR",
    "BUENOS AIRES": "BuenosAires_AR",
    "SANTA FE":     "SantaFe_AR"
}

func _ready() -> void:
    var path: String = "res://data/clima_zonas.json"
    if not FileAccess.file_exists(path):
        push_error("No se encontró JSON: " + path)
        return
    var txt: String = FileAccess.get_file_as_string(path)
    var parsed: Variant = JSON.parse_string(txt)
    if typeof(parsed) != TYPE_DICTIONARY:
        push_error("JSON inválido: no es diccionario")
        return
    if not (parsed as Dictionary).has("zonas"):
        push_error("JSON sin 'zonas'")
        return

    data = parsed

    # Dump para depurar
    var zonas_dict: Dictionary = data["zonas"]
    print("[ClimateService] Zonas:", zonas_dict.keys())
    for z in zonas_dict.keys():
        print("   ", z, " estaciones:", (zonas_dict[z] as Dictionary).keys())

func get_seasons() -> Array:
    return ["verano", "otoño", "invierno", "primavera"]

func get_display_zone_names() -> Array:
    return ["Cordoba", "Buenos Aires", "Santa Fe"]

# ⚠️ Renombrado: 'display_name' en vez de 'name' para no sombrear Node.name
func display_name_to_key(display_name: String) -> String:
    var k := display_name.strip_edges().to_upper()
    return display_to_key.get(k, "")

# Normaliza acentos/minúsculas para comparar seguro
func _norm(s: String) -> String:
    var t := s.strip_edges().to_lower()
    t = t.replace("á","a").replace("é","e").replace("í","i").replace("ó","o").replace("ú","u")
    t = t.replace("ñ","n")
    return t

# Busca la estación por equivalencia normalizada
func _find_season_key(zona_dict: Dictionary, season_in: String) -> String:
    var target := _norm(season_in)
    for k in zona_dict.keys():
        if _norm(String(k)) == target:
            return String(k)
    return ""

func get_zone_season(zone_key: String, season: String) -> Dictionary:
    if data.is_empty() or not data.has("zonas"):
        push_warning("get_zone_season: data vacío o sin 'zonas'")
        return {}

    var zonas: Dictionary = data["zonas"]
    if not zonas.has(zone_key):
        push_warning("Clave de zona no encontrada: " + zone_key)
        return {}

    var z: Dictionary = zonas[zone_key]
    var season_key := _find_season_key(z, season)
    if season_key == "":
        push_warning("Estación no encontrada para " + zone_key + " (recibida: '" + season + "')")
        return {}

    return z[season_key]
