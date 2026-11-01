extends Node3D

## Building3D.gd
## Pabellón arquitectónico moderno e interactivo para la mini-ciudad 3D de Cartagena.
## Incluye cartelería 3D nítida con badge de categoría, área de activación visual y diálogo.

@export var building_id: String = "parque_galilea"
@export var category_name: String = "[Constructora]"
@export var building_name: String = "Sala de Ventas: Parque Galilea"
@export var banner_color: Color = Color(0.08, 0.45, 0.35)
@export var canopy_color: Color = Color(0.12, 0.52, 0.42)
@export_multiline var advisor_intro: String = "¡Hola! Bienvenidos a Parque Galilea. Te explico cómo lograr el cierre de tu apartamento."

@onready var category_label: Label3D = $CategoryLabel3D
@onready var title_label: Label3D = $TitleLabel3D
@onready var prompt_label: Label3D = $PromptLabel3D
@onready var banner_mesh: MeshInstance3D = $Visuals/BannerMesh
@onready var canopy_mesh: MeshInstance3D = $Visuals/CanopyMesh

signal building_interacted(data: Dictionary)

func _ready() -> void:
	apply_appearance()
	if prompt_label:
		prompt_label.visible = false

func apply_appearance() -> void:
	if category_label:
		category_label.text = category_name
		category_label.fixed_size = false
		category_label.font_size = 28
		category_label.pixel_size = 0.006
		category_label.outline_size = 8
		category_label.outline_modulate = Color(0.02, 0.04, 0.08, 1.0)
	if title_label:
		title_label.text = building_name
		title_label.fixed_size = false
		title_label.font_size = 36
		title_label.pixel_size = 0.0065
		title_label.outline_size = 10
		title_label.outline_modulate = Color(0.02, 0.04, 0.08, 1.0)
	if prompt_label:
		prompt_label.text = "✦ [Presiona E o Haz Clic para Entrar a la Oficina] ✦"
		prompt_label.fixed_size = false
		prompt_label.font_size = 28
		prompt_label.pixel_size = 0.006
		prompt_label.outline_size = 8
		prompt_label.outline_modulate = Color(0.02, 0.04, 0.08, 1.0)
	
	if banner_mesh:
		var b_mat = StandardMaterial3D.new()
		b_mat.albedo_color = banner_color
		b_mat.roughness = 0.4
		banner_mesh.material_override = b_mat
		
	if canopy_mesh:
		var c_mat = StandardMaterial3D.new()
		c_mat.albedo_color = canopy_color
		c_mat.roughness = 0.5
		canopy_mesh.material_override = c_mat

func set_building(new_id: String, new_cat: String, new_name: String, new_intro: String, new_color: Color, new_canopy: Color) -> void:
	building_id = new_id
	category_name = new_cat
	building_name = new_name
	advisor_intro = new_intro
	banner_color = new_color
	canopy_color = new_canopy
	if is_inside_tree():
		apply_appearance()

func show_prompt(is_visible: bool) -> void:
	if prompt_label:
		prompt_label.visible = is_visible

func interact(_player: Node = null) -> void:
	var info: Dictionary = get_building_data()
	GameManager.start_dialogue(info, self)
	emit_signal("building_interacted", info)

func _on_interaction_area_input_event(_camera: Node, event: InputEvent, _position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		interact(null)

func get_building_data() -> Dictionary:
	var data: Dictionary = {
		"id": building_id,
		"name": building_name,
		"intro": advisor_intro,
		"options": []
	}
	
	match building_id:
		"parque_galilea":
			GameManager.complete_quest("visitar_constructora")
			data["options"] = [
				{
					"text": "¿Cómo se pagan los $50 millones de cuota inicial?",
					"response": "En preventa tienes gran flexibilidad: puedes pagar cuotas mensuales de $700.000 durante el plazo de construcción (10 a 24 meses). El excedente lo cubres con tus subsidios de Caja (Comfenalco) y Mi Casa Ya, y el saldo final con crédito del banco o FNA."
				},
				{
					"text": "Ver simulación de Cierre Financiero para Parque Galilea",
					"action": "open_calculator"
				},
				{
					"text": "¿Qué pasa si tengo los 3 subsidios (Caja + Mi Casa Ya + Mi Casa Va)?",
					"response": "¡Excelente! Eso se llama CONCURRENCIA. Al sumar los subsidios, tu cuota inicial y el saldo a financiar con el banco disminuyen drásticamente, haciendo que las cuotas mensuales del crédito te queden muy bajas."
				}
			]
			
		"comfenalco":
			data["options"] = [
				{
					"text": "¿Cuáles son los requisitos para el subsidio de Comfenalco?",
					"response": "1. Estar afiliado como trabajador formal o independiente.\n2. Ingresos del hogar menores a 4 SMMLV.\n3. No tener vivienda propia en ninguna parte del país.\n4. No haber recibido subsidio de vivienda antes."
				},
				{
					"text": "¿Cuánto dinero me entrega Comfenalco?",
					"response": "Si tu hogar gana hasta 2 SMMLV, recibes 30 SMMLV (aprox. " + HousingCalculator.format_cop(HousingCalculator.smmlv_to_cop(30.0)) + "). Si ganas entre 2 y 4 SMMLV, recibes 20 SMMLV."
				},
				{
					"text": "Radicar postulación de subsidio Comfenalco",
					"action": "approve_caja"
				}
			]
			
		"banco":
			data["options"] = [
				{
					"text": "¿Cuánto crédito me presta un banco o el FNA?",
					"response": "La cuota mensual de tu crédito no puede superar el 30% al 40% de los ingresos de tu hogar (Ley de Vivienda). Si ganas 2 SMMLV, tu cuota máxima recomendada ronda los $500.000 a $650.000 mensuales."
				},
				{
					"text": "¿Puedo usar mis Cesantías / Ahorro Voluntario (AVC)?",
					"response": "¡Sí! Puedes usar tus cesantías acumuladas en el Fondo Nacional del Ahorro (FNA) o fondos privados para sumarlas a la cuota inicial de Parque Galilea o amortizar el crédito."
				},
				{
					"text": "Solicitar Carta de Preaprobación de Crédito",
					"action": "preapprove_credit"
				}
			]
			
		"sisben":
			data["options"] = [
				{
					"text": "¿Cómo clasifica Sisbén IV para el subsidio Mi Casa Ya?",
					"response": "El Gobierno Nacional clasifica:\n• Grupo A1 a C8: Reciben 30 SMMLV de subsidio.\n• Grupo C9 a D20: No aplican a Mi Casa Ya del MinVivienda, pero pueden acceder a subsidio de Caja de Compensación o subsidio a la tasa de interés."
				},
				{
					"text": "¿Cómo se activa la Concurrencia de Subsidios?",
					"response": "La Concurrencia permite sumar el subsidio de tu Caja (Comfenalco, 30 SMMLV) + el subsidio de Mi Casa Ya (hasta 20 SMMLV adicionales), alcanzando hasta 50 SMMLV en total de ayuda del Estado."
				},
				{
					"text": "Consultar mi clasificación del Sisbén",
					"action": "open_calculator"
				}
			]
			
		"corvivienda":
			data["options"] = [
				{
					"text": "¿Qué es el subsidio 'Mi Casa Va' de Corvivienda?",
					"response": "Es el programa distrital de la Alcaldía de Cartagena gestionado por Corvivienda. Otorga un subsidio complementario para familias cartageneras que compran vivienda VIS en proyectos de la ciudad como Parque Galilea."
				},
				{
					"text": "¿Qué requisitos exige Corvivienda?",
					"response": "1. Residir en Cartagena durante los últimos años.\n2. No tener propiedad raíz.\n3. Contar con cierre financiero (combinando subsidio de Caja y crédito/ahorro)."
				},
				{
					"text": "Verificar elegibilidad para Corvivienda",
					"action": "approve_corvivienda"
				}
			]
			
	return data
