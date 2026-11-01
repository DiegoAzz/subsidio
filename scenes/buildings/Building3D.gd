extends Node3D

## Building3D.gd
## Edificio / Stand interactivo en 3D para la mini-ciudad de Cartagena.
## Incluye cartel 3D billboard, detección de proximidad y clic de ratón.

@export var building_id: String = "parque_galilea"
@export var building_name: String = "Sala de Ventas: Parque Galilea"
@export var banner_color: Color = Color(0.12, 0.48, 0.38)
@export var roof_color: Color = Color(0.85, 0.35, 0.2)
@export_multiline var advisor_intro: String = "¡Hola! Bienvenidos a Parque Galilea. Te explico cómo lograr el cierre de tu apartamento."

@onready var title_label: Label3D = $TitleLabel3D
@onready var prompt_label: Label3D = $PromptLabel3D
@onready var roof_mesh: MeshInstance3D = $Visuals/RoofMesh
@onready var banner_mesh: MeshInstance3D = $Visuals/BannerMesh

signal building_interacted(data: Dictionary)

func _ready() -> void:
	apply_appearance()
	if prompt_label:
		prompt_label.visible = false

func apply_appearance() -> void:
	if title_label:
		title_label.text = building_name
		title_label.modulate = Color(1, 1, 1)
	
	if banner_mesh:
		var mat = StandardMaterial3D.new()
		mat.albedo_color = banner_color
		banner_mesh.material_override = mat
		
	if roof_mesh:
		var r_mat = StandardMaterial3D.new()
		r_mat.albedo_color = roof_color
		roof_mesh.material_override = r_mat

func set_building(new_id: String, new_name: String, new_intro: String, new_color: Color, new_roof: Color) -> void:
	building_id = new_id
	building_name = new_name
	advisor_intro = new_intro
	banner_color = new_color
	roof_color = new_roof
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
			
		"fna_banco":
			data["options"] = [
				{
					"text": "¿Qué me conviene más: FNA o Banco tradicional?",
					"response": "El Fondo Nacional del Ahorro (FNA) es ideal si trasladas tus cesantías o abres un Ahorro Voluntario Contractual (AVC), no te cobra cuotas de manejo y tiene tasas preferenciales para VIS. Los bancos también ofrecen crédito hipotecario rápido si tienes buen historial crediticio."
				},
				{
					"text": "¿Qué es la carta de Preaprobado y por qué la pide Parque Galilea?",
					"response": "La constructora necesita garantizar que cuando el apartamento esté listo, una entidad financiera te desembolsará el dinero restante. El preaprobado certifica cuánto dinero te pueden prestar según tus ingresos."
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
