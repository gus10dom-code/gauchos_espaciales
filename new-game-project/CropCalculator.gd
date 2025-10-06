extends Node
class_name CropCalculator

signal crops_loaded(names: Array)

var CROPS: Dictionary = {}  # Se carga en _ready() desde res://data/cultivos.json

func _ready() -> void:
    var path: String = "res://data/cultivos.json"
    if FileAccess.file_exists(path):
        var txt: String = FileAccess.get_file_as_string(path)
        var parsed: Variant = JSON.parse_string(txt)
        if typeof(parsed) == TYPE_DICTIONARY and (parsed as Dictionary).has("crops"):
            CROPS = (parsed as Dictionary)["crops"]
        else:
            push_warning("cultivos.json inválido (no 'crops'); usando fallback mínimo.")
            _set_min_fallback()
    else:
        push_warning("No se encontró res://data/cultivos.json; usando fallback mínimo.")
        _set_min_fallback()

    # Avisa a la UI que ya cargó los cultivos (deberías ver 8 nombres)
    emit_signal("crops_loaded", get_crop_names())

func _set_min_fallback() -> void:
    CROPS = {
        "trigo": {"kc": 1.0, "base_days": 120, "base_N": 120, "t_opt": 18.0, "t_hi": 30.0, "opt_sm": 0.28, "riego_evento_mm": 25.0},
        "maíz":  {"kc": 1.1, "base_days": 130, "base_N": 140, "t_opt": 25.0, "t_hi": 35.0, "opt_sm": 0.30, "riego_evento_mm": 25.0}
    }

func get_crop_names() -> Array:
    return CROPS.keys()

# ------------ Helpers de redondeo/normalización ------------
func _norm(s: String) -> String:
    var t := s.strip_edges().to_lower()
    t = t.replace("á","a").replace("é","e").replace("í","i").replace("ó","o").replace("ú","u")
    t = t.replace("ñ","n")
    return t

func _normalize_crop_key(name: String) -> String:
    var target := _norm(name)
    for k in CROPS.keys():
        if _norm(String(k)) == target:
            return String(k)
    return name

func r1(x: float) -> float: return snappedf(x, 0.1)
func r3(x: float) -> float: return snappedf(x, 0.001)

func eto_mm_dia(t: float) -> float:
    if t < 12.0: return 2.0
    elif t < 18.0: return 3.0
    elif t < 24.0: return 4.0
    elif t < 30.0: return 5.0
    else: return 6.0

func thermal_factor(t_mean: float, t_opt: float, t_hi: float) -> float:
    if t_mean >= t_opt - 5.0 and t_mean <= t_opt + 5.0:
        return 1.0
    if t_mean > t_opt and t_mean <= t_hi:
        return max(0.2, 1.0 - 0.5 * (t_mean - t_opt) / max(0.1, (t_hi - t_opt)))
    if t_mean < t_opt - 5.0:
        return 0.7
    if t_mean > t_hi:
        return 0.2
    return 0.8

func soil_factor(sm: float, opt_sm: float) -> float:
    var d: float = abs(sm - opt_sm)
    if d <= 0.05: return 1.0
    elif d <= 0.10: return 0.8
    elif d <= 0.15: return 0.6
    else: return 0.3

# -------------------- Núcleo de cálculo --------------------
func calc(zone_packet: Dictionary, crop_name: String) -> Dictionary:
    var key := _normalize_crop_key(crop_name)
    if not CROPS.has(key):
        return {"error": "Cultivo no definido"}

    var c: Dictionary = CROPS[key]

    var t_mean: float     = float(zone_packet.get("t_mean", 20.0))
    var rain_total: float = float(zone_packet.get("rain_total_mm", 0.0))
    var soil_rz: float    = float(zone_packet.get("soil_rootzone_m3m3", 0.28))

    var kc: float         = float(c.get("kc", 1.0))
    var eto: float        = eto_mm_dia(t_mean)
    var etc_est: float    = kc * eto * 90.0  # mm en 3 meses

    var deficit: float    = max(0.0, etc_est - rain_total)
    var evento: float     = float(c.get("riego_evento_mm", 25.0))

    var freq_dias: int
    if deficit <= 0.1:
        freq_dias = -1
    else:
        freq_dias = int(round(evento / max(0.01, (deficit / 90.0))))

    var N_total: int      = int(c.get("base_N", 100))

    var tf: float         = thermal_factor(t_mean, float(c.get("t_opt", 20.0)), float(c.get("t_hi", 35.0)))
    var sf: float         = soil_factor(soil_rz, float(c.get("opt_sm", 0.30)))

    var water_ratio_natural: float = clamp(rain_total / max(1.0, etc_est), 0.0, 1.0)
    var p_sin: float               = clamp(0.1 + 0.5 * tf + 0.4 * min(sf, water_ratio_natural), 0.0, 1.0)

    var water_ratio_manejo: float  = 1.0
    var p_con: float               = clamp(0.15 + 0.6 * tf + 0.25 * sf + 0.2 * water_ratio_manejo, 0.0, 1.0)

    var riego_dias: Variant = null
    if freq_dias > 0:
        riego_dias = freq_dias

    return {
        "inputs": {
            "t_mean": r1(t_mean),
            "rain_total_mm": r1(rain_total),
            "soil_rootzone_m3m3": r3(soil_rz)
        },
        "ETc_estacion_mm": r1(etc_est),
        "riego_recomendado_mm": r1(deficit),
        "riego_cada_dias": riego_dias,
        "fertilizante_total_kg_ha": N_total,
        "prob_sin_manejo": int(round(p_sin * 100.0)),
        "prob_con_manejo": int(round(p_con * 100.0))
    }
