extends Control

# Rutas absolutas dentro de la escena (evita confusiones)
@onready var ob_prov: OptionButton      = get_node_or_null("VBoxContainer/OptionButton_Provincia")
@onready var ob_est: OptionButton       = get_node_or_null("VBoxContainer/OptionButton_Estacion")
@onready var ob_crop: OptionButton      = get_node_or_null("VBoxContainer/OptionButton_Cultivo")
@onready var bt_calc: Button            = get_node_or_null("VBoxContainer/Button_Calcular")
@onready var lb_riego: Label            = get_node_or_null("VBoxContainer/Label_Riego")
@onready var lb_fert: Label             = get_node_or_null("VBoxContainer/Label_Fertilizante")
@onready var lb_prob: Label             = get_node_or_null("VBoxContainer/Label_Prob")

@onready var climate: Node              = get_node_or_null("ClimateService")
@onready var calc: Node                 = get_node_or_null("CropCalculator")

var crops_list: Array[String] = ["trigo", "maíz", "arroz", "ajo"]

func _ready() -> void:
	print_tree_pretty()
	print("BTN:", bt_calc)
	print("climate:", climate, "  calc:", calc)
	# Validaciones claras en consola si falta algo
	if not _check_nodes(): return

	# Asegurar habilitado
	ob_prov.disabled = false
	ob_est.disabled = false
	ob_crop.disabled = false
	bt_calc.disabled = false

	# Limpiar labels
	lb_riego.text = ""
	lb_fert.text = ""
	lb_prob.text = ""

	# Poblar combos
	ob_prov.clear()
	var display_names: Array = []
	if climate and climate.has_method("get_display_zone_names"):
		display_names = climate.get_display_zone_names()
	else:
		display_names = ["Cordoba","Buenos Aires","Santa Fe"]
	for n in display_names:
		ob_prov.add_item(n)

	ob_est.clear()
	for s in ["verano","otoño","invierno","primavera"]:
		ob_est.add_item(s)

	ob_crop.clear()
	for c in crops_list:
		ob_crop.add_item(c)

	# Conectar botón
	bt_calc.pressed.connect(_on_calc_pressed)
   
func _on_calc_pressed() -> void:
	if ob_prov.selected < 0 or ob_est.selected < 0 or ob_crop.selected < 0:
		_show_msg("Selecciona provincia, estación y cultivo.")
		return

	var display_zone: String = ob_prov.get_item_text(ob_prov.selected)

	# --- SOLO UNA VEZ ---
	var zone_key: String = display_zone
	if climate and climate.has_method("display_name_to_key"):
		zone_key = climate.display_name_to_key(display_zone)
	# ---------------------

	var season: String = ob_est.get_item_text(ob_est.selected)
	var crop: String = ob_crop.get_item_text(ob_crop.selected)

	# DEBUG opcional
	# print("DEBUG sel:", display_zone, season, crop)
	# print("DEBUG zone_key:", zone_key)

	var packet: Dictionary = {}
	if climate and climate.has_method("get_zone_season"):
		packet = climate.get_zone_season(zone_key, season)
	# print("DEBUG packet:", packet)

	if packet.is_empty():
		_show_msg("No hay datos para esa combinación.")
		return

	if not calc or not calc.has_method("calc"):
		_show_msg("Falta el nodo 'CropCalculator' o su método 'calc'.")
		return

	var out: Dictionary = calc.calc(packet, crop)
	if out.has("error"):
		_show_msg(String(out["error"]))
		return

	var riego_txt := "Riego : %s mm" % out["riego_recomendado_mm"]
	if out["riego_cada_dias"] != null:
		riego_txt += " (cada %s días)" % out["riego_cada_dias"]

	lb_riego.text = riego_txt
	lb_fert.text  = "Fertilizante : %s kg/ha" % out["fertilizante_total_kg_ha"]
	lb_prob.text  = "Probabilidad de éxito: %s%% (s.m) / %s%% (c.m)" % [
		out["prob_sin_manejo"], out["prob_con_manejo"]
	]
func _show_msg(txt: String) -> void:
	if lb_riego: lb_riego.text = txt
	if lb_fert:  lb_fert.text = ""
	if lb_prob:  lb_prob.text = ""

func _check_nodes() -> bool:
	var ok := true
	if ob_prov == null: push_error("No se encontró: VBoxContainer/OptionButton_Provincia"); ok = false
	if ob_est  == null: push_error("No se encontró: VBoxContainer/OptionButton_Estacion");  ok = false
	if ob_crop == null: push_error("No se encontró: VBoxContainer/OptionButton_Cultivo");   ok = false
	if bt_calc == null: push_error("No se encontró: VBoxContainer/Button_Calcular");         ok = false
	if lb_riego== null: push_error("No se encontró: VBoxContainer/Label_Riego");             ok = false
	if lb_fert == null: push_error("No se encontró: VBoxContainer/Label_Fertilizante");      ok = false
	if lb_prob == null: push_error("No se encontró: VBoxContainer/Label_Prob");              ok = false
	if climate == null: push_error("No se encontró: ClimateService");                         ok = false
	if calc    == null: push_error("No se encontró: CropCalculator");                         ok = false
	return ok
