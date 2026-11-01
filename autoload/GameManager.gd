extends Node

## GameManager.gd
## Administra el estado del juego, la lista de requisitos (Checklist/Quests),
## el diálogo activo y el inventario de documentos del ciudadano.

signal quest_updated(quest_id: String, completed: bool)
signal dialogue_started(npc_data: Dictionary)
signal dialogue_ended()
signal financial_state_changed()

# Documentos y requisitos que el jugador debe conseguir
var documents: Dictionary = {
	"cedula": true, # Cédula de ciudadanía
	"cert_ingresos": false, # Carta laboral o extractos bancarios
	"preaprobado_banco": false, # Carta de viabilidad / preaprobado de banco o FNA
	"subsidio_caja": false, # Carta de postulación / asignación Comfenalco
	"sisben_hoja": false, # Certificado de grupo Sisbén IV
	"subsidio_micasaya": false, # Postulación Mi Casa Ya habilitada
	"subsidio_micasava": false, # Postulación Mi Casa Va (Corvivienda)
	"promesa_compraventa": false # Cierre con la Constructora
}

# Misiones / Pasos de la Hoja de Ruta
var quests: Array[Dictionary] = [
	{
		"id": "visitar_constructora",
		"title": "1. Conocer Proyecto Parque Galilea",
		"description": "Ve a la sala de ventas para cotizar el apartamento y pactar el plan de cuota inicial ($700.000/mes).",
		"completed": false,
		"location": "Sala de Ventas Parque Galilea"
	},
	{
		"id": "banco_preaprobado",
		"title": "2. Preaprobado Bancario / FNA",
		"description": "Pide una simulación y viabilidad de crédito hipotecario o traslada tus cesantías al FNA.",
		"completed": false,
		"location": "Banco / Fondo Nacional del Ahorro"
	},
	{
		"id": "caja_comfenalco",
		"title": "3. Subsidio Caja (Comfenalco)",
		"description": "Radica documentos en la Caja de Compensación para obtener hasta 30 SMMLV de subsidio.",
		"completed": false,
		"location": "Oficina Comfenalco Cartagena"
	},
	{
		"id": "sisben_micasaya",
		"title": "4. Activar Concurrencia (Mi Casa Ya)",
		"description": "Verifica tu grupo Sisbén (A1 a C8) para sumar el subsidio Mi Casa Ya al de la Caja.",
		"completed": false,
		"location": "Módulo MinVivienda / Sisbén"
	},
	{
		"id": "corvivienda_micasava",
		"title": "5. Subsidio Distrital (Mi Casa Va)",
		"description": "Pregunta en Corvivienda por el subsidio complementario de Cartagena.",
		"completed": false,
		"location": "Sede Corvivienda"
	},
	{
		"id": "cierre_financiero",
		"title": "6. ¡Firmar Cierre Financiero!",
		"description": "Regresa a Parque Galilea con todos tus subsidios y tu crédito para firmar la compra de tu casa.",
		"completed": false,
		"location": "Sala de Ventas Parque Galilea"
	}
]

# Datos del jugador local
var local_player_name: String = "Ciudadano"
var active_npc: Node = null

func complete_quest(quest_id: String) -> void:
	for q in quests:
		if q["id"] == quest_id:
			if not q["completed"]:
				q["completed"] = true
				emit_signal("quest_updated", quest_id, true)
				check_final_progress()
			break

func add_document(doc_id: String) -> void:
	if documents.has(doc_id):
		documents[doc_id] = true
		emit_signal("financial_state_changed")

func check_final_progress() -> void:
	var all_steps_ready: bool = true
	for q in quests:
		if q["id"] != "cierre_financiero" and not q["completed"]:
			all_steps_ready = false
			break
	if all_steps_ready and HousingCalculator.get_financial_summary()["is_financially_closed"]:
		complete_quest("cierre_financiero")

func start_dialogue(npc_data: Dictionary, npc_node: Node = null) -> void:
	active_npc = npc_node
	emit_signal("dialogue_started", npc_data)

func end_dialogue() -> void:
	active_npc = null
	emit_signal("dialogue_ended")
