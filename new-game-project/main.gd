extends Node
[gd_scene load_steps=4 format=3]

[ext_resource type="Script" path="res://UIController.gd" id="1"]
[ext_resource type="Script" path="res://ClimateService.gd" id="2"]
[ext_resource type="Script" path="res://CropCalculator.gd" id="3"]

[node name="main" type="Control"]
anchor_right = 1.0
anchor_bottom = 1.0
script = ExtResource("1")

[node name="VBoxContainer" type="VBoxContainer" parent="."]
offset_left = 24.0
offset_top = 24.0
offset_right = 360.0
offset_bottom = 540.0
theme_override_constants/separation = 10

[node name="OptionButton_Provincia" type="OptionButton" parent="VBoxContainer"]
size_flags_horizontal = 3

[node name="OptionButton_Estacion" type="OptionButton" parent="VBoxContainer"]
size_flags_horizontal = 3

[node name="OptionButton_Cultivo" type="OptionButton" parent="VBoxContainer"]
size_flags_horizontal = 3

[node name="Button_Calcular" type="Button" parent="VBoxContainer"]
text = "Calcular"
custom_minimum_size = Vector2(200, 40)
size_flags_horizontal = 3

[node name="Label_Riego" type="Label" parent="VBoxContainer"]
text = ""
autowrap_mode = 3

[node name="Label_Fertilizante" type="Label" parent="VBoxContainer"]
text = ""
autowrap_mode = 3

[node name="Label_Prob" type="Label" parent="VBoxContainer"]
text = ""
autowrap_mode = 3

[node name="ClimateService" type="Node" parent="."]
script = ExtResource("2")

[node name="CropCalculator" type="Node" parent="."]
script = ExtResource("3")
