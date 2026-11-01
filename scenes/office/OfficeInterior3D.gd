extends Node3D

## OfficeInterior3D.gd
## Interior 3D hiperrealista de la oficina / sala de atención de cada entidad.
## Incluye escritorio ejecutivo, asesor(a) uniformado(a), computador,
## afiches corporativos, maqueta del proyecto y diálogo de asesoría personalizado.

@onready var office_camera: Camera3D = $OfficeCamera3D
@onready var back_wall_mesh: MeshInstance3D = $Room/BackWall
@onready var brand_banner_mesh: MeshInstance3D = $Room/BrandBanner
@onready var brand_title_label: Label3D = $Room/BrandTitleLabel3D
@onready var advisor_name_label: Label3D = $Advisor/AdvisorNameLabel3D
@onready var advisor_body_mesh: MeshInstance3D = $Advisor/Visual/BodyMesh
@onready var advisor_speech_label: Label3D = $Advisor/SpeechBubble3D
@onready var poster_left_label: Label3D = $Room/PosterLeft/PosterLabel3D
@onready var poster_right_label: Label3D = $Room/PosterRight/PosterLabel3D
@onready var office_hud: CanvasLayer = $OfficeHUD

@onready var ui_entity_title: Label = $OfficeHUD/Panel/VBox/Header/EntityTitle
@onready var ui_advisor_name: Label = $OfficeHUD/Panel/VBox/Header/AdvisorName
@onready var ui_dialogue_text: RichTextLabel = $OfficeHUD/Panel/VBox/DialogueText
@onready var ui_options_container: VBoxContainer = $OfficeHUD/Panel/VBox/OptionsScroll/OptionsContainer
@onready var ui_exit_btn: Button = $OfficeHUD/Panel/VBox/Header/ExitBtn

signal exit_office_requested()

var current_entity_id: String = ""
var current_options: Array = []
var idle_time: float = 0.0

func _ready() -> void:
	if ui_exit_btn:
		ui_exit_btn.pressed.connect(_on_exit_pressed)

func _process(delta: float) -> void:
	# Animación sutil de respiración y presencia del asesor
	idle_time += delta
	var advisor_visual = $Advisor/Visual
	if advisor_visual:
		advisor_visual.position.y = 0.95 + sin(idle_time * 2.0) * 0.015

## Configura el interior de la oficina para la entidad seleccionada
func setup_office(entity_data: Dictionary) -> void:
	current_entity_id = entity_data.get("id", "parque_galilea")
	var entity_name: String = entity_data.get("name", "Oficina")
	var intro_text: String = entity_data.get("intro", "")
	current_options = entity_data.get("options", [])
	
	var primary_color: Color = Color(0.08, 0.45, 0.35)
	var advisor_name: String = "Lic. Carolina Méndez"
	var advisor_role: String = "Asesora Comercial Senior - Parque Galilea"
	var poster_left: String = "TORRES PARQUE GALILEA\n• Apartamentos VIS 54m²\n• 3 Alcobas + Balcón\n• Piscina y Canchas"
	var poster_right: String = "PLAN FINANCIERO VIS\n• Cuota Inicial: ~$50M\n• Cuotas: $700.000/mes\n• Aceptamos Subsidios"
	
	match current_entity_id:
		"parque_galilea":
			primary_color = Color(0.08, 0.45, 0.35)
			advisor_name = "Lic. Carolina Méndez"
			advisor_role = "Asesora Comercial - Parque Galilea"
			poster_left = "PARQUE GALILEA VIS\nApartamentos con subsidio\nEntrega 2026 en Cartagena"
			poster_right = "CIERRE FINANCIERO\nCuota mensual preventa:\n$700.000 COP"
		"comfenalco":
			primary_color = Color(0.12, 0.36, 0.78)
			advisor_name = "Dr. Roberto Herrera"
			advisor_role = "Especialista en Subsidios - Comfenalco Cartagena"
			poster_left = "SUBSIDIO FAMILIAR\nHasta 30 SMMLV para afiliados\nIngresos hasta 4 SMMLV"
			poster_right = "CONCURRENCIA VIGENTE\nSuma Comfenalco + Mi Casa Ya\nTotal hasta 50 SMMLV"
		"banco":
			primary_color = Color(0.10, 0.22, 0.46)
			advisor_name = "Ing. Fernando Castro"
			advisor_role = "Oficial de Crédito Hipotecario - FNA & Bancos"
			poster_left = "CRÉDITO HIPOTECARIO\nFinanciación hasta 80% VIS\nPlazo hasta 30 años"
			poster_right = "FONDO NACIONAL DEL AHORRO\nTraslada tus cesantías / AVC\nTasa preferencial UVR o Pesos"
		"sisben":
			primary_color = Color(0.85, 0.42, 0.15)
			advisor_name = "Dra. Martha Salcedo"
			advisor_role = "Delegada Sisbén IV & MinVivienda"
			poster_left = "SISBÉN IV NACIONAL\nGrupos A1 a C8 habilitados\npara Mi Casa Ya"
			poster_right = "MINISTERIO DE VIVIENDA\nCobertura a la tasa de interés\ny subsidio directo"
		"corvivienda":
			primary_color = Color(0.78, 0.15, 0.18)
			advisor_name = "Dr. Jairo Peñaranda"
			advisor_role = "Coordinador de Vivienda - Alcaldía de Cartagena"
			poster_left = "ALCALDÍA DE CARTAGENA\nCorvivienda: Mi Casa Va\nSubsidio Distrital Heroico"
			poster_right = "REQUISITOS CARTAGENA\nResidencia comprobada en la ciudad\nNo propietarios"

	# Aplicar colores corporativos al muro de acento
	if back_wall_mesh:
		var wall_mat = StandardMaterial3D.new()
		wall_mat.albedo_color = primary_color.lerp(Color(0.2, 0.2, 0.2), 0.2)
		wall_mat.roughness = 0.6
		back_wall_mesh.material_override = wall_mat

	# Aplicar banner corporativo
	if brand_banner_mesh:
		var b_mat = StandardMaterial3D.new()
		b_mat.albedo_color = primary_color
		b_mat.metallic = 0.2
		b_mat.roughness = 0.4
		brand_banner_mesh.material_override = b_mat

	# Ropa del asesor
	if advisor_body_mesh:
		var body_mat = StandardMaterial3D.new()
		body_mat.albedo_color = primary_color
		body_mat.roughness = 0.5
		advisor_body_mesh.material_override = body_mat

	# Textos 3D en la pared
	if brand_title_label:
		brand_title_label.text = entity_name.to_upper()
	if advisor_name_label:
		advisor_name_label.text = "%s\n%s" % [advisor_name, advisor_role]
	if poster_left_label:
		poster_left_label.text = poster_left
	if poster_right_label:
		poster_right_label.text = poster_right

	# Globo de diálogo 3D sobre el asesor
	if advisor_speech_label:
		advisor_speech_label.text = "«¡Hola! Bienvenido a nuestra oficina. Tome asiento, por favor.»"

	# Configurar HUD interactivo inferior
	if ui_entity_title:
		ui_entity_title.text = entity_name
	if ui_advisor_name:
		ui_advisor_name.text = "Atendido por: %s (%s)" % [advisor_name, advisor_role]
	if ui_dialogue_text:
		ui_dialogue_text.text = intro_text

	populate_options(current_options)
	office_hud.visible = true

func populate_options(options: Array) -> void:
	for c in ui_options_container.get_children():
		c.queue_free()

	for opt in options:
		var btn = Button.new()
		btn.text = "💼 " + opt.get("text", "")
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.custom_minimum_size = Vector2(0, 36)
		btn.pressed.connect(_on_option_selected.bind(opt))
		ui_options_container.add_child(btn)

func _on_option_selected(opt: Dictionary) -> void:
	if opt.has("response"):
		ui_dialogue_text.text = opt["response"]
		if advisor_speech_label:
			advisor_speech_label.text = "«" + opt["response"].left(120) + "...»"

	if opt.has("action"):
		match opt["action"]:
			"open_calculator":
				var parent_node = get_parent()
				if parent_node and parent_node.has_node("HUD"):
					parent_node.get_node("HUD").open_calculator()
			"approve_caja":
				GameManager.complete_quest("caja_comfenalco")
				GameManager.add_document("subsidio_caja")
				HousingCalculator.caja_approved = true
				ui_dialogue_text.text = "✓ ¡Documentos radicados en Comfenalco!\nCumples con los requisitos. Subsidio pre-asignado a la espera de la promesa de compraventa de Parque Galilea."
			"preapprove_credit":
				GameManager.complete_quest("banco_preaprobado")
				GameManager.add_document("preaprobado_banco")
				HousingCalculator.bank_credit_approved = true
				ui_dialogue_text.text = "✓ ¡Estudio de crédito preaprobado!\nSe ha emitido tu Carta de Viabilidad Financiera para presentar en Parque Galilea."
			"approve_corvivienda":
				GameManager.complete_quest("corvivienda_micasava")
				GameManager.add_document("subsidio_micasava")
				HousingCalculator.micasava_approved = true
				ui_dialogue_text.text = "✓ ¡Postulación registrada en Corvivienda!\nRegistrado para el subsidio complementario distrital 'Mi Casa Va'."

func _on_exit_pressed() -> void:
	emit_signal("exit_office_requested")
