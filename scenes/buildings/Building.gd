extends Node2D

## Building.gd
## Clase base para edificios y salas de atención en la mini-ciudad de Cartagena.
## Maneja el área de interacción, el indicador visual de proximidad y los diálogos educativos.

@export var building_id: String = "parque_galilea"
@export var building_name: String = "Sala de Ventas Parque Galilea"
@export var banner_color: Color = Color(0.15, 0.55, 0.45)
@export_multiline var advisor_intro: String = "¡Hola! Bienvenidos a Parque Galilea. Te explico cómo lograr el cierre de tu apartamento."

@onready var prompt_label: Label = $PromptLabel
@onready var title_label: Label = $Banner/TitleLabel
@onready var banner_panel: PanelContainer = $Banner
@onready var roof: Polygon2D = $Visuals/Roof

signal building_interacted(data: Dictionary)

func _ready() -> void:
	apply_appearance()
	if prompt_label:
		prompt_label.visible = false

func apply_appearance() -> void:
	if title_label:
		title_label.text = building_name
	if banner_panel:
		var style: StyleBoxFlat = StyleBoxFlat.new()
		style.bg_color = banner_color
		style.set_corner_radius_all(6)
		banner_panel.add_theme_stylebox_override("panel", style)

func set_building(new_id: String, new_name: String, new_intro: String, new_color: Color = Color(0.15, 0.45, 0.7), roof_color: Color = Color(0.78, 0.32, 0.22)) -> void:
	building_id = new_id
	building_name = new_name
	advisor_intro = new_intro
	banner_color = new_color
	if is_inside_tree():
		apply_appearance()
		if roof:
			roof.color = roof_color

func show_prompt(visible_state: bool) -> void:
	if prompt_label:
		prompt_label.visible = visible_state

func interact(_player: Node = null) -> void:
	var info: Dictionary = get_building_data()
	GameManager.start_dialogue(info, self)
	emit_signal("building_interacted", info)

func _on_interaction_area_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		interact(null)

func get_building_data() -> Dictionary:
	var summary: Dictionary = HousingCalculator.get_financial_summary()
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
					"response": "En preventa tienes gran flexibilidad: puedes pagar cuotas mensuales de $700.000 durante el plazo de construcción (10 a 24 meses). El excedente lo cubres con tus subsidios de Caja (Comfenalco) y Mi Casa Ya, y el resto con crédito del banco o FNA."
				},
				{
					"text": "Ver simulación de Cierre Financiero para Parque Galilea",
					"action": "open_calculator"
				},
				{
					"text": "¿Qué pasa si tengo los 3 subsidios (Caja + Mi Casa Ya + Mi Casa Va)?",
					"response": "¡Excelente! Eso se llama CONCURRENCIA. Al sumar los subsidios, tu cuota inicial y el saldo a financiar con el banco disminuyen drásticamente, haciendo que las cuotas mensuales del banco te queden muy bajas."
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
			
		"fna_banco":
			data["options"] = [
				{
					"text": "¿Qué me conviene más: FNA o Banco tradicional?",
					"response": "El Fondo Nacional del Ahorro (FNA) es ideal si trasladas tus cesantías o abres un Ahorro Voluntario Contractual (AVC), no te cobra cuotas de manejo y tiene tasas preferenciales para VIS. Los bancos también ofrecen crédito hipotecario rápido si tienes buen historial crediticio."
				},
				{
					"text": "¿Qué es la carta de Preaprobado y por qué la pide Parque Galilea?",
					"response": "La constructora necesita garantizar que cuando el edificio esté terminado, una entidad financiera te desembolsará el dinero restante. El preaprobado certifica cuánto dinero te pueden prestar según tus ingresos."
				},
				{
					"text": "Solicitar estudio y carta de Preaprobado",
					"action": "approve_bank"
				}
			]
			
		"micasaya":
			data["options"] = [
				{
					"text": "¿Cómo funciona Mi Casa Ya con el Sisbén IV?",
					"response": "Para aplicar a Mi Casa Ya debes tener encuesta Sisbén IV clasificada entre A1 y C8. Ya no se necesita postular en una oficina del gobierno: ¡la constructora o el banco sube tus datos a la plataforma de MinVivienda automáticamente!"
				},
				{
					"text": "¿Puedo sumar Mi Casa Ya con el subsidio de Comfenalco?",
					"response": "¡Sí! Si tu hogar gana hasta 2 SMMLV, la ley te permite la Concurrencia de Subsidios: Comfenalco te entrega 30 SMMLV y Mi Casa Ya te suma 20 SMMLV adicionales (¡50 SMMLV en total!)."
				},
				{
					"text": "Validar Sisbén para Mi Casa Ya",
					"action": "approve_micasaya"
				}
			]
			
		"corvivienda":
			data["options"] = [
				{
					"text": "¿Qué es el subsidio 'Mi Casa Va' de Cartagena?",
					"response": "Es un subsidio complementario distrital otorgado por la Alcaldía de Cartagena a través de Corvivienda para hogares vulnerables que compran vivienda VIS en proyectos de la ciudad."
				},
				{
					"text": "Postular a subsidio distrital Corvivienda",
					"action": "approve_micasava"
				}
			]
			
	return data
