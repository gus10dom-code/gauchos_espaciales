extends Window
class_name GameConsole

signal result_ready(score: int, summary: String)

@onready var vb: VBoxContainer    = get_node("VBox")
@onready var lbl_reco: Label      = get_node("VBox/Label_Reco")
@onready var row1: HBoxContainer  = get_node("VBox/Row1")
@onready var row2: HBoxContainer  = get_node("VBox/Row2")
@onready var row3: HBoxContainer  = get_node("VBox/Row3")
@onready var sb_mm: SpinBox       = get_node("VBox/Row1/SB_RiegoMM")
@onready var sb_freq: SpinBox     = get_node("VBox/Row2/SB_Freq")
@onready var sb_fert: SpinBox     = get_node("VBox/Row3/SB_Fert")
@onready var btn_eval: Button     = get_node("VBox/HB_Buttons/Btn_Evaluar")
@onready var btn_cancel: Button   = get_node("VBox/HB_Buttons/Btn_Cancelar")
@onready var lbl_result: Label    = get_node("VBox/Label_Resultado")
@onready var btn_close: Button    = get_node_or_null("Btn_Close")  # opcional: X interna

# Recomendaciones cargadas desde UIController.open_with()
# {"mm": float, "freq": int|null, "N": float}
var _rec: Dictionary = {}

const SEASON_DAYS: int = 90  # ventana de 3 meses para comparar eventos

func _ready() -> void:
    visible = false
    title = "Management simulation"

    # Textos en inglés
    get_node("VBox/Row1/L1").text = "Total irrigation (mm)"
    get_node("VBox/Row2/L2").text = "Frequency (days)"
    get_node("VBox/Row3/L3").text = "Fertilizer (kg/ha)"
    btn_eval.text   = "evaluate"
    btn_cancel.text = "cancel"

    # Límites
    sb_mm.min_value = 0;   sb_mm.max_value = 2000; sb_mm.step = 1
    sb_freq.min_value = 1; sb_freq.max_value = 90; sb_freq.step = 1
    sb_fert.min_value = 0; sb_fert.max_value = 400; sb_fert.step = 1

    # Conexiones
    btn_eval.pressed.connect(_on_eval_pressed)
    btn_cancel.pressed.connect(func() -> void: hide())

    # ❌ cierre por barra de título (si el sistema la muestra)
    if not is_connected("close_requested", Callable(self, "_on_close_requested")):
        connect("close_requested", Callable(self, "_on_close_requested"))

    # ❌ cierre por botón X interno (si existe)
    if btn_close and not btn_close.pressed.is_connected(_on_close_pressed):
        btn_close.pressed.connect(_on_close_pressed)

func _on_close_requested() -> void:
    hide()

func _on_close_pressed() -> void:
    hide()

# Abre la ventana con las recomendaciones actuales
func open_with(reco: Dictionary) -> void:
    if reco.is_empty():
        lbl_reco.text = "No recommendations yet. Calculate first."
        row2.visible = false
        lbl_result.text = ""
        popup_centered(Vector2i(560, 380))
        return

    # Normalizar y almacenar
    var mm: float = float(reco.get("riego_recomendado_mm", 0.0))
    var N: float  = float(reco.get("fertilizante_total_kg_ha", 0.0))
    var f_any: Variant = reco.get("riego_cada_dias", null)
    var f_val: Variant = null
    if f_any != null:
        f_val = int(f_any)

    _rec = {"mm": mm, "N": N, "freq": f_val}

    # Precargar valores en los SpinBox
    sb_mm.value = mm
    sb_fert.value = N
    if f_val == null:
        row2.visible = false
    else:
        row2.visible = true
        sb_freq.value = int(f_val)

    var every_txt: String = (str(f_val) if f_val != null else "N/A")
    lbl_reco.text = "Recommended → Irrigation: %.1f mm | Every: %s | Fertilizer: %d kg/ha" % [mm, every_txt, int(N)]
    lbl_result.text = ""
    popup_centered(Vector2i(560, 380))

# Botón "evaluate"
func _on_eval_pressed() -> void:
    if _rec.is_empty():
        lbl_result.text = "No recommendations loaded."
        return

    var u_mm: float = float(sb_mm.value)
    var u_N: float  = float(sb_fert.value)
    var u_freq_any: Variant = null
    if row2.visible:
        u_freq_any = int(sb_freq.value)

    var score: int = _score(u_mm, u_freq_any, u_N)
    var msg: String = _verdict_text(score)

    # --- Agua ahorrada o desperdiciada ---
    var rec_mm: float = float(_rec.get("mm", 0.0))
    var delta_mm: float = u_mm - rec_mm
    var delta_m3_ha: float = abs(delta_mm) * 10.0  # 1 mm/ha = 10 m³

    var water_txt: String
    if delta_mm > 0.0:
        water_txt = "Over by %.1f mm (%.1f m³/ha wasted)" % [delta_mm, delta_m3_ha]
    elif delta_mm < 0.0:
        water_txt = "Under by %.1f mm (%.1f m³/ha saved)" % [abs(delta_mm), delta_m3_ha]
    else:
        water_txt = "Matched recommendation (no extra water)."

    # Mostrar resultado + agua
    lbl_result.text = "Result: %d%% — %s\n%s" % [score, msg, water_txt]

    # Emitir señal con resumen (opcional)
    emit_signal("result_ready", score, "%s | %s" % [msg, water_txt])

# =========================
# Scoring 0..100 (con frecuencia fuerte)
# =========================
func _score(u_mm: float, u_freq: Variant, u_N: float) -> int:
    # Pesos: subimos frecuencia para que impacte más
    var w_mm: float   = 0.45
    var w_freq: float = 0.35
    var w_N: float    = 0.20

    var rec_mm: float = float(_rec.get("mm", 0.0))
    var rec_N:  float = float(_rec.get("N", 0.0))
    var rec_f_any: Variant = _rec.get("freq", null)

    # --- error por total de mm y N (igual que antes) ---
    var err_mm: float = min(1.0, abs(u_mm - rec_mm) / max(1.0, rec_mm))
    var err_Nf: float = min(1.0, abs(u_N  - rec_N)  / max(1.0, rec_N))

    # --- componente de frecuencia reforzado ---
    var err_freq: float = 0.0
    var w_sum: float = w_mm + w_N

    if rec_f_any != null and u_freq != null:
        var rec_f: int = int(rec_f_any)
        var u_f:  int = int(u_freq)

        # Cantidad de eventos en la estación (redondeo razonable)
        var rec_events: int = max(1, int(round(float(SEASON_DAYS) / float(rec_f))))
        var usr_events: int = max(1, int(round(float(SEASON_DAYS) / float(u_f))))

        # Lámina por evento
        var rec_event_mm: float = rec_mm / float(rec_events)
        var usr_event_mm: float = u_mm  / float(usr_events)

        # Error por cantidad de eventos
        var err_events: float = min(1.0, abs(usr_events - rec_events) / float(max(1, rec_events)))

        # Error por mm por evento
        var err_event_mm: float = min(1.0, abs(usr_event_mm - rec_event_mm) / max(1.0, rec_event_mm))

        # Combinamos ambos (50/50)
        err_freq = clamp(0.5 * err_events + 0.5 * err_event_mm, 0.0, 1.0)

        # Sesgo: si riegas menos frecuente que lo recomendado, penaliza +20%
        if u_f > rec_f:
            err_freq = min(1.0, err_freq * 1.2)

        w_sum += w_freq
    else:
        # Si no hay frecuencia recomendada, no la consideramos
        w_freq = 0.0

    var err_total: float = (w_mm * err_mm + w_N * err_Nf + w_freq * err_freq) / w_sum
    return int(round(clamp(1.0 - err_total, 0.0, 1.0) * 100.0))

func _verdict_text(score: int) -> String:
    if score >= 90: return "Excellent (near optimal)."
    elif score >= 75: return "Very good."
    elif score >= 60: return "Acceptable (can improve)."
    elif score >= 40: return "Low: adjust dose/frequency."
    else: return "Very low: out of recommended range."
