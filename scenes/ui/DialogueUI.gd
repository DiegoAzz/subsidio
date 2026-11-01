extends Control

## DialogueUI.gd
## Maneja los diálogos de asesoría en cada entidad y sala de ventas.
## Muestra las opciones y respuestas didácticas para la compra de vivienda.

@onready var entity_name_label: Label = $Panel/VBox/Header/EntityName
@onready var dialogue_text: RichTextLabel = $Panel/VBox/DialogueText
@onready var options_container: VBoxContainer = $Panel/VBox/OptionsContainer
@onready var close_btn: Button = $Panel/VBox/Header/CloseBtn

var current_data: Dictionary = {}

func _ready() -> void:
	visible = false
	close_btn.pressed.connect(_on_close_pressed)
	GameManager.dialogue_started.connect(display_dialogue)
	GameManager.dialogue_ended.connect(func(): visible = false)

func display_dialogue(_data: Dictionary) -> void:
	# La atención ahora es presencial en 3D dentro de la oficina (OfficeInterior3D)
	visible = false

func _on_option_clicked(opt: Dictionary) -> void:
	if opt.has("response"):
		dialogue_text.text = opt["response"]
		
	if opt.has("action"):
		match opt["action"]:
			"open_calculator":
				var parent_hud = get_parent()
				if parent_hud and parent_hud.has_method("open_calculator"):
					parent_hud.open_calculator()
			"approve_caja":
				GameManager.complete_quest("caja_comfenalco")
				GameManager.add_document("subsidio_caja")
				HousingCalculator.caja_approved = true
				dialogue_text.text = "✓ ¡Documentos radicados en Comfenalco!\nCumples con los requisitos. Subsidio pre-asignado a la espera de la promesa de compraventa."
			"approve_bank":
				GameManager.complete_quest("banco_preaprobado")
				GameManager.add_document("preaprobado_banco")
				HousingCalculator.bank_credit_approved = true
				dialogue_text.text = "✓ ¡Estudio aprobado!\nSe ha emitido tu carta de Viabilidad Financiera / Preaprobado de Crédito para presentar en Parque Galilea."
			"approve_micasaya":
				GameManager.complete_quest("sisben_micasaya")
				GameManager.add_document("subsidio_micasaya")
				HousingCalculator.micasaya_approved = true
				dialogue_text.text = "✓ ¡Sisbén verificado!\nTu hogar está habilitado para el subsidio concurrente de Mi Casa Ya a través de MinVivienda."
			"approve_micasava":
				GameManager.complete_quest("corvivienda_micasava")
				GameManager.add_document("subsidio_micasava")
				HousingCalculator.micasava_approved = true
				dialogue_text.text = "✓ ¡Postulación recibida en Corvivienda!\nRegistrado para el subsidio complementario distrital 'Mi Casa Va'."

func _on_close_pressed() -> void:
	visible = false
	GameManager.end_dialogue()
