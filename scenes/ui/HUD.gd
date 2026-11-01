extends CanvasLayer

## HUD.gd
## Interfaz principal del usuario (HUD).
## Contiene acceso a la Calculadora, Hoja de Ruta, Panel de Conexión Coolify y Chat en Tiempo Real.

@onready var calculator_ui: Control = $CalculatorUI
@onready var quest_ui: Control = $QuestUI
@onready var dialogue_ui: Control = $DialogueUI
@onready var multiplayer_modal: Control = $MultiplayerModal

# Botones superiores
@onready var btn_calc: Button = $TopBar/HBox/BtnCalc
@onready var btn_quests: Button = $TopBar/HBox/BtnQuests
@onready var btn_net: Button = $TopBar/HBox/BtnNet
@onready var btn_fullscreen: Button = $TopBar/HBox/BtnFullscreen
@onready var status_lbl: Label = $TopBar/HBox/StatusLbl

# Modal de red
@onready var server_input: LineEdit = $MultiplayerModal/Panel/VBox/ServerInput
@onready var btn_connect: Button = $MultiplayerModal/Panel/VBox/BtnConnect
@onready var btn_host: Button = $MultiplayerModal/Panel/VBox/BtnHost
@onready var net_status_lbl: Label = $MultiplayerModal/Panel/VBox/NetStatusLbl
@onready var btn_close_net: Button = $MultiplayerModal/Panel/VBox/CloseNetBtn

# Chat
@onready var chat_log: RichTextLabel = $ChatPanel/VBox/ChatLog
@onready var chat_input: LineEdit = $ChatPanel/VBox/HBox/ChatInput
@onready var btn_send_chat: Button = $ChatPanel/VBox/HBox/BtnSend

func _ready() -> void:
	btn_calc.pressed.connect(open_calculator)
	btn_quests.pressed.connect(open_quests)
	btn_net.pressed.connect(toggle_multiplayer_modal)
	btn_fullscreen.pressed.connect(toggle_fullscreen)
	btn_close_net.pressed.connect(func(): multiplayer_modal.visible = false)
	
	btn_connect.pressed.connect(_on_connect_pressed)
	btn_host.pressed.connect(_on_host_pressed)
	
	btn_send_chat.pressed.connect(_send_chat)
	chat_input.text_submitted.connect(func(_t): _send_chat())
	
	# Señales de red
	NetworkManager.connection_succeeded.connect(_on_net_connected)
	NetworkManager.connection_failed.connect(_on_net_failed)
	NetworkManager.chat_message_received.connect(_on_chat_received)
	
	multiplayer_modal.visible = false
	add_chat_system_message("¡Bienvenido a Cartagena! Visita la Sala de Ventas de Parque Galilea para conocer los requisitos de tu casa.")

func open_calculator() -> void:
	calculator_ui.visible = true
	calculator_ui.update_all_calculations()

func open_quests() -> void:
	quest_ui.visible = true
	quest_ui.refresh_quests()

func toggle_multiplayer_modal() -> void:
	multiplayer_modal.visible = not multiplayer_modal.visible

func _on_connect_pressed() -> void:
	var addr: String = server_input.text.strip_edges()
	if addr == "":
		addr = "127.0.0.1"
	net_status_lbl.text = "Conectando a %s..." % addr
	NetworkManager.connect_to_server(addr, 9090, addr.begins_with("wss://"))

func _on_host_pressed() -> void:
	net_status_lbl.text = "Iniciando servidor local en puerto 9090..."
	var err = NetworkManager.start_server(9090)
	if err == OK:
		net_status_lbl.text = "✓ Servidor activo en puerto 9090."
		btn_net.text = "🌐 Servidor Local Activo"
	else:
		net_status_lbl.text = "Error al iniciar servidor."

func _on_net_connected() -> void:
	net_status_lbl.text = "✓ Conectado exitosamente al VPS."
	btn_net.text = "🌐 Conectado (Online)"
	add_chat_system_message("Conectado al servidor multijugador.")

func _on_net_failed() -> void:
	net_status_lbl.text = "✕ Conexión fallida. Revisa la dirección del VPS."
	add_chat_system_message("Error al conectar con el servidor.")

func _send_chat() -> void:
	var msg: String = chat_input.text.strip_edges()
	if msg == "":
		return
	chat_input.clear()
	
	if NetworkManager.is_online:
		NetworkManager.rpc("send_chat_message", msg)
	else:
		# Modo offline local
		_on_chat_received("Tú (Offline)", msg)

func toggle_fullscreen() -> void:
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		btn_fullscreen.text = "⛶ Pantalla Completa"
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		btn_fullscreen.text = "🗗 Salir de Pantalla Completa"

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_F11:
		toggle_fullscreen()

func _on_chat_received(sender: String, msg: String) -> void:
	chat_log.append_text("[color=#60cdff]<b>%s:</b>[/color] %s\n" % [sender, msg])

func add_chat_system_message(msg: String) -> void:
	chat_log.append_text("[color=#ffd15c]<b>[Sistema]:</b> %s[/color]\n" % msg)
