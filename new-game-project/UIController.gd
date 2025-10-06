extends Control

# ---------- UI ----------
@onready var ob_prov: OptionButton = get_node("VBoxContainer/OptionButton_Provincia")
@onready var ob_est:  OptionButton = get_node("VBoxContainer/OptionButton_Estacion")
@onready var ob_crop: OptionButton = get_node("VBoxContainer/OptionButton_Cultivo")
@onready var bt_calc: Button       = get_node("VBoxContainer/Button_Calcular")
@onready var bt_practice: Button   = get_node("VBoxContainer/Button_Practicar")
@onready var lb_riego: Label       = get_node("VBoxContainer/Label_Riego")
@onready var lb_fert:  Label       = get_node("VBoxContainer/Label_Fertilizante")
@onready var lb_prob:  Label       = get_node("VBoxContainer/Label_Prob")

# ---------- Services ----------
@onready var climate: Node  = get_node("ClimateService")
@onready var calc:    Node  = get_node("CropCalculator")
@onready var sim_console: Window = get_node("SimConsole") # GameConsole.gd

# ---------- State (for mapping OptionButton IDs -> real strings) ----------
var _zones: Array = []
var _seasons_es: Array = []
var _crops_es: Array = []
var _last_out: Dictionary = {}

# ---------- Label masks (ES -> EN) ----------
const SEASON_ES_TO_EN := {
    "verano":"summer", "otoño":"autumn", "invierno":"winter", "primavera":"spring"
}
const CROP_ES_TO_EN := {
    "trigo":"wheat", "maíz":"maize", "arroz":"rice", "ajo":"garlic",
    "soja":"soybean", "papa":"potato", "girasol":"sunflower", "zapallo":"pumpkin"
}

func _translate_label(es_text: String) -> String:
    if SEASON_ES_TO_EN.has(es_text):
        return SEASON_ES_TO_EN[es_text]
    if CROP_ES_TO_EN.has(es_text):
        return CROP_ES_TO_EN[es_text]
    return es_text # provinces / fallback

# ============================================================
func _ready() -> void:
    # Visible texts in English
    bt_calc.text     = "calculate"
    bt_practice.text = "Practice"
    lb_riego.text = ""
    lb_fert.text  = ""
    lb_prob.text  = ""

    # Start state
    bt_practice.disabled = true
    sim_console.visible  = false

    # Signals
    bt_calc.pressed.connect(_on_calc_pressed)
    bt_practice.pressed.connect(_on_practice_pressed)
    if sim_console.has_signal("result_ready"):
        sim_console.connect("result_ready", Callable(self, "_on_sim_result"))

    # Populate UI
    _populate_provincias_y_estaciones()
    _fill_crops()

# ============================================================
# Provinces (display names) and seasons (show EN, keep ES IDs via arrays)
func _populate_provincias_y_estaciones() -> void:
    # Provinces
    _zones = []
    if climate and climate.has_method("get_display_zone_names"):
        _zones = climate.get_display_zone_names()
    else:
        _zones = ["Cordoba", "Buenos Aires", "Santa Fe"]

    ob_prov.clear()
    for i in _zones.size():
        ob_prov.add_item(_translate_label(_zones[i]), i)  # id = index

    # Seasons (ES real keys come from ClimateService when possible)
    if climate and climate.has_method("get_seasons"):
        _seasons_es = climate.get_seasons()
    else:
        _seasons_es = ["verano", "otoño", "invierno", "primavera"]

    ob_est.clear()
    for i in _seasons_es.size():
        ob_est.add_item(_translate_label(_seasons_es[i]), i)  # id = index

# Crops (from CropCalculator JSON)
func _fill_crops() -> void:
    _crops_es = []
    if calc and calc.has_method("get_crop_names"):
        _crops_es = calc.get_crop_names()
    _crops_es.sort()

    ob_crop.clear()
    for i in _crops_es.size():
        ob_crop.add_item(_translate_label(_crops_es[i]), i)  # id = index

# ============================================================
# Calculate
func _on_calc_pressed() -> void:
    if ob_prov.selected < 0 or ob_est.selected < 0 or ob_crop.selected < 0:
        lb_prob.text = "Select province, season and crop."
        return

    # Map province visible -> internal zone key
    var prov_idx: int = ob_prov.get_selected_id()
    var display_zone: String = _zones[prov_idx]
    var zone_key: String = display_zone
    if climate and climate.has_method("display_name_to_key"):
        zone_key = climate.display_name_to_key(display_zone)

    # Real ES strings from arrays (ids are indices)
    var season_es: String = _seasons_es[ob_est.get_selected_id()]
    var crop_es:   String = _crops_es[ob_crop.get_selected_id()]

    # Retrieve climate packet for zone+season
    var packet: Dictionary = {}
    if climate and climate.has_method("get_zone_season"):
        packet = climate.get_zone_season(zone_key, season_es)

    if packet.is_empty():
        lb_prob.text = "No data for that combination."
        bt_practice.disabled = true
        return

    if not calc or not calc.has_method("calc"):
        lb_prob.text = "CropCalculator node/method is missing."
        bt_practice.disabled = true
        return

    var out: Dictionary = calc.calc(packet, crop_es)
    if out.has("error"):
        lb_prob.text = String(out["error"])
        bt_practice.disabled = true
        return

    _last_out = out
    bt_practice.disabled = false

    # Show results (English)
    var riego_txt: String = "Recommended irrigation: %s mm" % out["riego_recomendado_mm"]
    if out["riego_cada_dias"] != null:
        riego_txt += " (every %s days)" % out["riego_cada_dias"]
    lb_riego.text = riego_txt

    lb_fert.text = "Total fertilizer: %s kg/ha" % out["fertilizante_total_kg_ha"]
    lb_prob.text = "Minimum success (climate): %s%%  | Recommended: %s%%" % [
        out["prob_sin_manejo"], out["prob_con_manejo"]
    ]

# ============================================================
# Practice window
func _on_practice_pressed() -> void:
    if _last_out.is_empty():
        lb_prob.text = "Calculate first to practice."
        return
    if sim_console and sim_console.has_method("open_with"):
        sim_console.visible = true
        sim_console.call_deferred("open_with", _last_out)

# Receive score (0..100) and summary from GameConsole
func _on_sim_result(score: int, _summary: String) -> void:
    if _last_out.is_empty():
        return
    var p_min: int = int(_last_out.get("prob_sin_manejo", 0))
    var p_max: int = int(_last_out.get("prob_con_manejo", p_min))
    var est_plan: int = int(round(p_min + (p_max - p_min) * (float(score) / 100.0)))
    var final_pct: int = int(round((p_min + est_plan) / 2.0))

    var grade: String
    var grade_msg: String
    if final_pct >= 90:
        grade = "A"; grade_msg = "Perfect crop."
    elif final_pct >= 80:
        grade = "B"; grade_msg = "Great crop."
    elif final_pct >= 70:
        grade = "C"; grade_msg = "Good crop (can improve)."
    elif final_pct >= 60:
        grade = "D"; grade_msg = "Weak: adjust management."
    else:
        grade = "E"; grade_msg = "Poor: out of recommended range."

    lb_prob.text = "Minimum: %d%% | Recommended: %d%% | Your plan: %d%%\n" % [p_min, p_max, est_plan]
    lb_prob.text += "Final result: %d%% → %s — %s" % [final_pct, grade, grade_msg]


func _on_sim_console_close_requested() -> void:
    pass # Replace with function body.
