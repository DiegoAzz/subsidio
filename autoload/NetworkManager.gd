extends Node

## NetworkManager.gd
## Administrador de red multijugador en tiempo real usando WebSocketMultiplayerPeer.
## Compatible con exportación Web (HTML5/WASM) y despliegue en contenedores Coolify (VPS).

const DEFAULT_PORT: int = 9090
const DEFAULT_HOST: String = "127.0.0.1"

# Señales de estado de conexión
signal connection_succeeded()
signal connection_failed()
signal server_disconnected()
signal player_connected(peer_id: int, player_info: Dictionary)
signal player_disconnected(peer_id: int)
signal remote_player_moved(peer_id: int, pos: Vector2)
signal chat_message_received(sender_name: String, message: String)

var peer: WebSocketMultiplayerPeer = WebSocketMultiplayerPeer.new()
var is_server: bool = false
var is_online: bool = false
var players: Dictionary = {} # peer_id -> { "name": String, "position": Vector2, "status": String }

func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	
	# Detectar si se está ejecutando como servidor dedicado headless en Coolify
	var args: PackedStringArray = OS.get_cmdline_args()
	if "--server" in args or "--headless" in args:
		var port_env: String = OS.get_environment("PORT")
		var port: int = port_env.to_int() if port_env != "" else DEFAULT_PORT
		print("[Servidor Dedicado Coolify] Iniciando en puerto WebSocket: ", port)
		start_server(port)

## Inicia el servidor dedicado con WebSocket
func start_server(port: int = DEFAULT_PORT) -> Error:
	peer = WebSocketMultiplayerPeer.new()
	var err: Error = peer.create_server(port)
	if err != OK:
		print("[Red] Error al iniciar servidor WebSocket: ", err)
		return err
	multiplayer.multiplayer_peer = peer
	is_server = true
	is_online = true
	print("[Red] Servidor WebSocket corriendo en puerto ", port)
	return OK

## Conecta el cliente al servidor (soporta ws:// local y wss:// en producción Coolify)
func connect_to_server(address: String = DEFAULT_HOST, port: int = DEFAULT_PORT, use_wss: bool = false) -> Error:
	peer = WebSocketMultiplayerPeer.new()
	var url: String = ""
	if address.begins_with("ws://") or address.begins_with("wss://"):
		url = address
	else:
		var scheme: String = "wss://" if use_wss else "ws://"
		url = "%s%s:%d" % [scheme, address, port]
		
	print("[Red] Conectando a servidor WebSocket: ", url)
	var err: Error = peer.create_client(url)
	if err != OK:
		print("[Red] Falló la creación del cliente WebSocket: ", err)
		emit_signal("connection_failed")
		return err
	multiplayer.multiplayer_peer = peer
	is_server = false
	is_online = true
	return OK

## Desconexión limpia
func disconnect_network() -> void:
	if peer:
		peer.close()
	multiplayer.multiplayer_peer = null
	is_online = false
	is_server = false
	players.clear()

# --- Callbacks de Conexión ---

func _on_connected_to_server() -> void:
	print("[Red] Conectado exitosamente al servidor.")
	var my_id: int = multiplayer.get_unique_id()
	rpc_id(1, "register_player", GameManager.local_player_name)
	emit_signal("connection_succeeded")

func _on_connection_failed() -> void:
	print("[Red] Conexión fallida.")
	disconnect_network()
	emit_signal("connection_failed")

func _on_server_disconnected() -> void:
	print("[Red] Desconectado del servidor.")
	disconnect_network()
	emit_signal("server_disconnected")

func _on_peer_connected(id: int) -> void:
	print("[Red] Nuevo par conectado con ID: ", id)

func _on_peer_disconnected(id: int) -> void:
	print("[Red] Par desconectado: ", id)
	if players.has(id):
		players.erase(id)
	emit_signal("player_disconnected", id)

# --- Métodos RPC para sincronización ---

@rpc("any_peer", "reliable")
func register_player(player_name: String) -> void:
	var sender_id: int = multiplayer.get_remote_sender_id()
	players[sender_id] = {
		"name": player_name,
		"position": Vector2(640, 400),
		"status": "Explorando Cartagena"
	}
	# Notificar a todos los clientes del nuevo jugador
	rpc("update_player_list", players)
	emit_signal("player_connected", sender_id, players[sender_id])

@rpc("authority", "reliable")
func update_player_list(all_players: Dictionary) -> void:
	players = all_players

@rpc("any_peer", "unreliable")
func update_player_transform(pos: Vector2) -> void:
	var sender_id: int = multiplayer.get_remote_sender_id()
	if players.has(sender_id):
		players[sender_id]["position"] = pos
	# Reenviar a los demás pares
	if is_server:
		rpc("sync_remote_player_transform", sender_id, pos)

@rpc("authority", "unreliable")
func sync_remote_player_transform(peer_id: int, pos: Vector2) -> void:
	if peer_id != multiplayer.get_unique_id():
		if players.has(peer_id):
			players[peer_id]["position"] = pos
		emit_signal("remote_player_moved", peer_id, pos)

@rpc("any_peer", "reliable")
func send_chat_message(message: String) -> void:
	var sender_id: int = multiplayer.get_remote_sender_id()
	var s_name: String = "Anonimo"
	if players.has(sender_id):
		s_name = players[sender_id]["name"]
	elif sender_id == 1:
		s_name = "Servidor"
	
	if is_server:
		# Distribuir mensaje a todos
		rpc("receive_chat_message", s_name, message)
	else:
		emit_signal("chat_message_received", s_name, message)

@rpc("authority", "reliable")
func receive_chat_message(sender_name: String, message: String) -> void:
	emit_signal("chat_message_received", sender_name, message)
