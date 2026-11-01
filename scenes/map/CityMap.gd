extends Node2D

## CityMap.gd
## Mapa principal de la mini-ciudad de Cartagena.
## Gestiona la aparición del jugador local, jugadores remotos en red y configuración de los edificios.

@onready var local_player: CharacterBody2D = $YSortEntities/Player
@onready var entities_container: Node2D = $YSortEntities
@onready var hud: CanvasLayer = $HUD

var remote_player_scene: PackedScene = preload("res://scenes/player/Player.tscn")
var remote_players: Dictionary = {}

func _ready() -> void:
	# Configurar edificios específicos en el mapa
	setup_buildings()
	
	# Eventos de red
	NetworkManager.player_connected.connect(_on_remote_player_connected)
	NetworkManager.player_disconnected.connect(_on_remote_player_disconnected)
	NetworkManager.remote_player_moved.connect(_on_remote_player_moved)

func setup_buildings() -> void:
	# 1. Parque Galilea (Constructora - Verde azulado)
	var galilea = $YSortEntities/BuildingGalilea
	if galilea:
		galilea.set_building(
			"parque_galilea",
			"Sala de Ventas: Parque Galilea",
			"¡Bienvenido a Parque Galilea! Nuestro proyecto VIS está diseñado para que con tus subsidios y un plan de cuotas de $700.000 logres tu casa propia en Cartagena.",
			Color(0.12, 0.48, 0.38),
			Color(0.85, 0.35, 0.2)
		)

	# 2. Comfenalco Cartagena (Caja de compensación - Azul institucional)
	var comfenalco = $YSortEntities/BuildingComfenalco
	if comfenalco:
		comfenalco.set_building(
			"comfenalco",
			"Caja Comfenalco Cartagena",
			"¡Hola! En Comfenalco Cartagena te asesoramos para postular al subsidio familiar de vivienda (hasta 30 SMMLV).",
			Color(0.15, 0.35, 0.75),
			Color(0.2, 0.45, 0.85)
		)

	# 3. FNA & Bancos (Financiera - Azul oscuro / Oro)
	var banco = $YSortEntities/BuildingBanco
	if banco:
		banco.set_building(
			"fna_banco",
			"Entidad Financiera: FNA y Bancos",
			"Te ayudamos a tramitar la Carta de Preaprobado y trasladar tus cesantías o ahorro voluntario.",
			Color(0.18, 0.24, 0.36),
			Color(0.3, 0.4, 0.5)
		)

	# 4. Sisbén & Mi Casa Ya (Nacional - Naranja / Amarillo)
	var sisben = $YSortEntities/BuildingSisben
	if sisben:
		sisben.set_building(
			"micasaya",
			"Módulo Sisbén IV & Mi Casa Ya",
			"Revisa tu grupo del Sisbén (A1 a C8) para acceder al subsidio concurrente del Gobierno Nacional.",
			Color(0.85, 0.5, 0.1),
			Color(0.9, 0.65, 0.2)
		)

	# 5. Corvivienda (Alcaldía Cartagena - Rojo / Amarillo cartagenero)
	var corvivienda = $YSortEntities/BuildingCorvivienda
	if corvivienda:
		corvivienda.set_building(
			"corvivienda",
			"Corvivienda: Mi Casa Va",
			"Conoce las convocatorias distritales de la Alcaldía de Cartagena para subsidios complementarios.",
			Color(0.75, 0.2, 0.2),
			Color(0.85, 0.75, 0.2)
		)

func _on_remote_player_connected(peer_id: int, info: Dictionary) -> void:
	if peer_id == multiplayer.get_unique_id() or remote_players.has(peer_id):
		return
	var r_player: CharacterBody2D = remote_player_scene.instantiate()
	r_player.is_local_player = false
	r_player.name = "Player_%d" % peer_id
	entities_container.add_child(r_player)
	r_player.global_position = info.get("position", Vector2(640, 400))
	if r_player.name_label:
		r_player.name_label.text = info.get("name", "Vecino")
	remote_players[peer_id] = r_player

func _on_remote_player_disconnected(peer_id: int) -> void:
	if remote_players.has(peer_id):
		remote_players[peer_id].queue_free()
		remote_players.erase(peer_id)

func _on_remote_player_moved(peer_id: int, new_pos: Vector2) -> void:
	if remote_players.has(peer_id):
		var p = remote_players[peer_id]
		p.global_position = p.global_position.lerp(new_pos, 0.4)
