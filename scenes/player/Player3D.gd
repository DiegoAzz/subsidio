extends CharacterBody3D

## Player3D.gd
## Controlador del personaje en 3D para la maqueta interactiva de Cartagena.
## Movimiento suave en plano XZ, rotación hacia el movimiento e interacción con stands.

@export var speed: float = 7.5
@export var is_local_player: bool = true

@onready var visual: Node3D = $Visual
@onready var name_label: Label3D = $NameLabel3D
@onready var status_badge: Label3D = $StatusBadge3D

var current_interactable: Node = null

func _ready() -> void:
	if is_local_player:
		name_label.text = GameManager.local_player_name
	update_status_display()
	HousingCalculator.calculations_updated.connect(func(_d): update_status_display())

func update_status_display() -> void:
	var summary: Dictionary = HousingCalculator.get_financial_summary()
	if summary["is_financially_closed"]:
		status_badge.text = "✓ ¡Listo para Firmar!"
		status_badge.modulate = Color(0.2, 0.95, 0.3)
	else:
		var pct: int = int((1.0 - (summary["deficit"] / summary["total_price"])) * 100.0)
		status_badge.text = "Progreso: %d%%" % max(0, pct)
		status_badge.modulate = Color(1.0, 0.8, 0.2)

func _physics_process(delta: float) -> void:
	if not is_local_player:
		return
		
	var input_dir: Vector2 = Vector2.ZERO
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT) or Input.is_action_pressed("move_left") or Input.is_action_pressed("ui_left"):
		input_dir.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT) or Input.is_action_pressed("move_right") or Input.is_action_pressed("ui_right"):
		input_dir.x += 1.0
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP) or Input.is_action_pressed("move_up") or Input.is_action_pressed("ui_up"):
		input_dir.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN) or Input.is_action_pressed("move_down") or Input.is_action_pressed("ui_down"):
		input_dir.y += 1.0
		
	input_dir = input_dir.normalized()
	
	# Mover en plano XZ
	var direction: Vector3 = Vector3(input_dir.x, 0, input_dir.y)
	velocity = direction * speed
	move_and_slide()
	
	# Límites suaves dentro de la mini-ciudad
	global_position.x = clamp(global_position.x, -14.0, 14.0)
	global_position.z = clamp(global_position.z, -12.0, 15.0)
	global_position.y = 0.55 # Altura rasante sobre aceras y asfalto de Kenney
	
	# Rotación del modelo hacia la dirección de movimiento
	if direction.length_squared() > 0.01:
		var target_angle: float = atan2(direction.x, direction.z)
		visual.rotation.y = lerp_angle(visual.rotation.y, target_angle, 12.0 * delta)
		
	# Interacción al presionar E o Espacio
	if (Input.is_key_pressed(KEY_E) or Input.is_action_just_pressed("interact") or Input.is_action_just_pressed("ui_accept")) and current_interactable:
		if current_interactable.has_method("interact"):
			current_interactable.interact(self)

func _on_interaction_area_entered(area: Area3D) -> void:
	var parent: Node = area.get_parent()
	if parent.has_method("interact"):
		current_interactable = parent
		if parent.has_method("show_prompt"):
			parent.show_prompt(true)

func _on_interaction_area_exited(area: Area3D) -> void:
	var parent: Node = area.get_parent()
	if current_interactable == parent:
		if parent.has_method("show_prompt"):
			parent.show_prompt(false)
		current_interactable = null
