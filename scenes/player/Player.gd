extends CharacterBody2D

## Player.gd
## Controlador del jugador en perspectiva 2D Top-Down.
## Soporta control local, cámara con interpolación suave, detección de interactuables y sincronización en red.

@export var speed: float = 240.0
@export var is_local_player: bool = true

@onready var name_label: Label = $Visual/NameLabel
@onready var status_badge: Label = $Visual/StatusBadge
@onready var interaction_ray: RayCast2D = $InteractionRay
@onready var camera: Camera2D = $Camera2D

var current_interactable: Node = null
var sync_timer: float = 0.0
const SYNC_INTERVAL: float = 0.05 # 20 ticks por segundo para sync de red

func _ready() -> void:
	if is_local_player:
		name_label.text = GameManager.local_player_name
		if camera:
			camera.enabled = false
	else:
		if camera:
			camera.enabled = false
		set_physics_process(false)
	update_status_display()
	HousingCalculator.calculations_updated.connect(func(_d): update_status_display())

func update_status_display() -> void:
	var summary: Dictionary = HousingCalculator.get_financial_summary()
	if summary["is_financially_closed"]:
		status_badge.text = "✓ ¡Listo para Firmar!"
		status_badge.modulate = Color(0.2, 0.9, 0.3)
	else:
		var pct: int = int((1.0 - (summary["deficit"] / summary["total_price"])) * 100.0)
		status_badge.text = "Progreso: %d%%" % max(0, pct)
		status_badge.modulate = Color(1.0, 0.75, 0.2)

func _physics_process(delta: float) -> void:
	if not is_local_player:
		return
		
	# Lectura robusta de controles (WASD, Flechas o acciones configuradas)
	var input_vector: Vector2 = Vector2.ZERO
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT) or Input.is_action_pressed("move_left") or Input.is_action_pressed("ui_left"):
		input_vector.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT) or Input.is_action_pressed("move_right") or Input.is_action_pressed("ui_right"):
		input_vector.x += 1.0
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP) or Input.is_action_pressed("move_up") or Input.is_action_pressed("ui_up"):
		input_vector.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN) or Input.is_action_pressed("move_down") or Input.is_action_pressed("ui_down"):
		input_vector.y += 1.0
		
	input_vector = input_vector.normalized()
	
	velocity = input_vector * speed
	move_and_slide()
	global_position.x = clamp(global_position.x, 30.0, 1250.0)
	global_position.y = clamp(global_position.y, 75.0, 695.0)
	
	# Orientar raycast de interacción según la dirección de movimiento
	if input_vector != Vector2.ZERO:
		interaction_ray.target_position = input_vector * 45.0
		
	# Interacción al presionar 'E', 'Espacio' o 'Enter'
	if (Input.is_key_pressed(KEY_E) or Input.is_action_just_pressed("interact") or Input.is_action_just_pressed("ui_accept")) and current_interactable:
		if current_interactable.has_method("interact"):
			current_interactable.interact(self)
			
	# Sincronización en red hacia el servidor si estamos conectados
	if NetworkManager.is_online and not NetworkManager.is_server:
		sync_timer += delta
		if sync_timer >= SYNC_INTERVAL:
			sync_timer = 0.0
			NetworkManager.rpc_id(1, "update_player_transform", global_position)

func _on_interaction_area_entered(area: Area2D) -> void:
	var parent: Node = area.get_parent()
	if parent.has_method("interact"):
		current_interactable = parent
		if parent.has_method("show_prompt"):
			parent.show_prompt(true)

func _on_interaction_area_exited(area: Area2D) -> void:
	var parent: Node = area.get_parent()
	if current_interactable == parent:
		if parent.has_method("show_prompt"):
			parent.show_prompt(false)
		current_interactable = null
