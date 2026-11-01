extends Node3D

## CityMap3D.gd
## Maqueta interactiva 3D de la mini-ciudad de Cartagena (VIS Parque Galilea)
## Utiliza los tiles modulares reales de Kenney (recursos/Models/gLTF) con paleta sRGB calibrada.

@onready var tiles_container: Node3D = $Tiles
@onready var props_container: Node3D = $Props
@onready var buildings_container: Node3D = $Buildings
@onready var player: CharacterBody3D = $Player3D
@onready var camera: Camera3D = $Camera3D
@onready var hud: CanvasLayer = $HUD
@onready var office_interior: Node3D = $OfficeInterior3D

var in_office_mode: bool = false

# Materiales de paleta vibrante estilo Kenney (evita sobreexposición y lavado blanco)
var palette_materials: Dictionary = {}

func get_palette_mat(mat_name: String) -> StandardMaterial3D:
	if palette_materials.has(mat_name):
		return palette_materials[mat_name]
	
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.roughness = 0.85
	mat.metallic = 0.0
	
	match mat_name:
		"Grass":
			mat.albedo_color = Color(0.35, 0.58, 0.22) # Verde natural vivo
		"Stone":
			mat.albedo_color = Color(0.64, 0.61, 0.54) # Adoquín / acera crema arenisca (sin quemado)
		"Asphalt":
			mat.albedo_color = Color(0.22, 0.23, 0.25) # Asfalto oscuro contrastado
		"Grey_Asphalt", "Light_Asphalt":
			mat.albedo_color = Color(0.32, 0.33, 0.35)
		"White":
			mat.albedo_color = Color(0.90, 0.90, 0.90) # Señalización vial blanca
		"Water":
			mat.albedo_color = Color(0.18, 0.52, 0.78, 0.88)
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			mat.roughness = 0.15
			mat.metallic = 0.15
		"Alternate_Dirt":
			mat.albedo_color = Color(0.68, 0.50, 0.32)
		"Sand":
			mat.albedo_color = Color(0.85, 0.75, 0.52)
		"FrontColor":
			mat.albedo_color = Color(0.20, 0.50, 0.18)
		_:
			mat.albedo_color = Color(0.65, 0.65, 0.65)
			
	palette_materials[mat_name] = mat
	return mat

func apply_tile_palette(node: Node) -> void:
	if node is MeshInstance3D:
		var mesh: Mesh = node.mesh
		if mesh:
			for i in range(mesh.get_surface_count()):
				var orig_mat = node.get_active_material(i)
				var mat_name: String = ""
				if orig_mat:
					mat_name = orig_mat.resource_name
				if mat_name != "":
					node.set_surface_override_material(i, get_palette_mat(mat_name))
	for child in node.get_children():
		apply_tile_palette(child)

func _ready() -> void:
	build_road_network()
	build_city_props()
	setup_buildings()
	
	# Asegurar cámara inicial de la ciudad
	camera.current = true
	
	# Conexión con el sistema de oficinas 3D
	GameManager.dialogue_started.connect(_on_enter_office)
	if office_interior:
		office_interior.exit_office_requested.connect(_on_exit_office)
		var off_cam = office_interior.get_node_or_null("OfficeCamera3D")
		if off_cam:
			off_cam.current = false
		var off_hud = office_interior.get_node_or_null("OfficeHUD")
		if off_hud:
			off_hud.visible = false

func _process(delta: float) -> void:
	if in_office_mode:
		return
		
	if player and camera:
		# Cámara isométrica suave que sigue al jugador en las calles
		var target_cam_pos: Vector3 = player.global_position + Vector3(0.0, 13.0, 14.0)
		camera.global_position = camera.global_position.lerp(target_cam_pos, delta * 4.5)
		camera.look_at(player.global_position + Vector3(0.0, 1.0, 0.0), Vector3.UP)

func _on_enter_office(entity_data: Dictionary) -> void:
	if not office_interior:
		return
		
	in_office_mode = true
	office_interior.setup_office(entity_data)
	
	var off_cam = office_interior.get_node_or_null("OfficeCamera3D")
	if off_cam:
		off_cam.current = true
		
	if player:
		player.set_physics_process(false)
		player.velocity = Vector3.ZERO
		
	if hud:
		hud.visible = false

func _on_exit_office() -> void:
	in_office_mode = false
	
	if camera:
		camera.current = true
		
	if player:
		player.set_physics_process(true)
		
	if hud:
		hud.visible = true
		
	if office_interior:
		var off_hud = office_interior.get_node_or_null("OfficeHUD")
		if off_hud:
			off_hud.visible = false
			
	GameManager.end_dialogue()

## Coloca un tile de Kenney en la cuadrícula de 3x3 metros
func place_kenney_tile(tile_name: String, grid_x: int, grid_z: int, rot_deg: float = 0.0) -> void:
	var path: String = "res://recursos/Models/gLTF/" + tile_name + ".gltf"
	var scene = load(path)
	if not scene:
		return
		
	var wrapper: Node3D = Node3D.new()
	wrapper.name = "%s_%d_%d" % [tile_name, grid_x, grid_z]
	wrapper.position = Vector3(grid_x * 3.0, 0.0, grid_z * 3.0)
	
	var inst: Node3D = scene.instantiate()
	inst.position = Vector3(-1.5, 0.0, 1.5)
	wrapper.add_child(inst)
	apply_tile_palette(inst)
	wrapper.rotation_degrees.y = rot_deg
	tiles_container.add_child(wrapper)

func build_road_network() -> void:
	# 1. PLAZA CENTRAL (Plaza de la Paz / Bolívar) con adoquines de piedra (grid -1..1, -1..1)
	place_kenney_tile("roadTile_002", -1, -1, 0.0)
	place_kenney_tile("roadTile_002",  0, -1, 0.0)
	place_kenney_tile("roadTile_002",  1, -1, 0.0)
	place_kenney_tile("roadTile_002", -1,  0, 0.0)
	place_kenney_tile("roadTile_001",  0,  0, 0.0) # Fuente / espejo de agua central
	place_kenney_tile("roadTile_002",  1,  0, 0.0)
	place_kenney_tile("roadTile_002", -1,  1, 0.0)
	place_kenney_tile("roadTile_002",  0,  1, 0.0)
	place_kenney_tile("roadTile_002",  1,  1, 0.0)

	# 2. ANILLO VIAL INTERNO (Calles con aceras y pasos peatonales conectando distritos)
	# Avenida Norte (Z = -2)
	place_kenney_tile("roadTile_027", -2, -2, 0.0)   # Esquina NO
	place_kenney_tile("roadTile_026", -1, -2, 90.0)
	place_kenney_tile("roadTile_025",  0, -2, 90.0)  # Cebra Norte hacia la plaza
	place_kenney_tile("roadTile_026",  1, -2, 90.0)
	place_kenney_tile("roadTile_027",  2, -2, 90.0)   # Esquina NE

	# Avenida Sur (Z = 2)
	place_kenney_tile("roadTile_027", -2,  2, 270.0)  # Esquina SO
	place_kenney_tile("roadTile_026", -1,  2, 90.0)
	place_kenney_tile("roadTile_025",  0,  2, 90.0)   # Cebra Sur
	place_kenney_tile("roadTile_026",  1,  2, 90.0)
	place_kenney_tile("roadTile_027",  2,  2, 180.0)  # Esquina SE

	# Avenida Oeste (X = -2)
	place_kenney_tile("roadTile_026", -2, -1, 0.0)
	place_kenney_tile("roadTile_025", -2,  0, 0.0)   # Cebra Oeste
	place_kenney_tile("roadTile_026", -2,  1, 0.0)

	# Avenida Este (X = 2)
	place_kenney_tile("roadTile_026",  2, -1, 0.0)
	place_kenney_tile("roadTile_025",  2,  0, 0.0)   # Cebra Este
	place_kenney_tile("roadTile_026",  2,  1, 0.0)

	# 3. ACCESOS A PABELLONES Y AVENIDAS EXTERNAS
	# Hacia Parque Galilea (NE: X=3, Z=-3)
	place_kenney_tile("roadTile_026",  3, -2, 90.0)
	place_kenney_tile("roadTile_002",  3, -3, 0.0)
	place_kenney_tile("roadTile_002",  4, -3, 0.0)
	place_kenney_tile("roadTile_002",  4, -2, 0.0)

	# Hacia Comfenalco (NO: X=-3, Z=-3)
	place_kenney_tile("roadTile_026", -3, -2, 90.0)
	place_kenney_tile("roadTile_002", -3, -3, 0.0)
	place_kenney_tile("roadTile_002", -4, -3, 0.0)
	place_kenney_tile("roadTile_002", -4, -2, 0.0)

	# Hacia FNA y Bancos (SO: X=-3, Z=3)
	place_kenney_tile("roadTile_026", -3,  2, 90.0)
	place_kenney_tile("roadTile_002", -3,  3, 0.0)
	place_kenney_tile("roadTile_002", -4,  3, 0.0)
	place_kenney_tile("roadTile_002", -4,  2, 0.0)

	# Hacia Sisbén IV y Mi Casa Ya (SE: X=3, Z=3)
	place_kenney_tile("roadTile_026",  3,  2, 90.0)
	place_kenney_tile("roadTile_002",  3,  3, 0.0)
	place_kenney_tile("roadTile_002",  4,  3, 0.0)
	place_kenney_tile("roadTile_002",  4,  2, 0.0)

	# Hacia Corvivienda (Sur: X=0, Z=3..4)
	place_kenney_tile("roadTile_026",  0,  3, 0.0)
	place_kenney_tile("roadTile_002", -1,  4, 0.0)
	place_kenney_tile("roadTile_002",  0,  4, 0.0)
	place_kenney_tile("roadTile_002",  1,  4, 0.0)

	# 4. CANAL DE AGUA DE CARTAGENA (Norte Z = -4) CON PUENTE
	place_kenney_tile("roadTile_001", -3, -4, 0.0)
	place_kenney_tile("roadTile_001", -2, -4, 0.0)
	place_kenney_tile("roadTile_001", -1, -4, 0.0)
	place_kenney_tile("roadTile_187",  0, -4, 0.0) # Puente vial sobre el canal
	place_kenney_tile("roadTile_001",  1, -4, 0.0)
	place_kenney_tile("roadTile_001",  2, -4, 0.0)
	place_kenney_tile("roadTile_001",  3, -4, 0.0)

	# 5. ZONAS VERDES (Césped plano roadTile_029 en toda la periferia)
	var grass_coords: Array = [
		Vector2i(-4, -1), Vector2i(-4, 0), Vector2i(-4, 1),
		Vector2i(4, -1),  Vector2i(4, 0),  Vector2i(4, 1),
		Vector2i(-3, -1), Vector2i(-3, 1),
		Vector2i(3, -1),  Vector2i(3, 1),
		Vector2i(-2, 3),  Vector2i(-1, 3), Vector2i(1, 3), Vector2i(2, 3),
		Vector2i(-2, -3), Vector2i(-1, -3), Vector2i(1, -3), Vector2i(2, -3),
		Vector2i(-4, -4), Vector2i(4, -4),
		Vector2i(-2, 4),  Vector2i(2, 4),
		Vector2i(-3, 4),  Vector2i(3, 4),
		Vector2i(-4, 4),  Vector2i(4, 4)
	]
	for coord in grass_coords:
		place_kenney_tile("roadTile_029", coord.x, coord.y, 0.0)

func build_city_props() -> void:
	# Farolas de calle en las esquinas de aceras
	var lamp_positions: Array = [
		Vector3(-4.5, 0.55, -4.5),
		Vector3(4.5, 0.55, -4.5),
		Vector3(-4.5, 0.55, 4.5),
		Vector3(4.5, 0.55, 4.5),
		Vector3(0.0, 0.55, 10.5),
		Vector3(0.0, 0.55, -10.5)
	]
	for pos in lamp_positions:
		create_street_lamp(pos)

	# Palmeras / Árboles tropicales de Cartagena en parques y plaza
	var tree_positions: Array = [
		Vector3(-9.0, 0.55, -3.0),
		Vector3(9.0, 0.55, -3.0),
		Vector3(-9.0, 0.55, 3.0),
		Vector3(9.0, 0.55, 3.0),
		Vector3(-3.0, 0.55, 9.0),
		Vector3(3.0, 0.55, 9.0),
		Vector3(-6.0, 0.55, -9.0),
		Vector3(6.0, 0.55, -9.0)
	]
	for pos in tree_positions:
		create_lowpoly_tree(pos)

	# Escultura / Obelisco en la fuente central
	create_fountain_monument(Vector3(0, 0.55, 0))

func create_street_lamp(pos: Vector3) -> void:
	var lamp: Node3D = Node3D.new()
	lamp.position = pos
	
	# Poste
	var pole_mesh: MeshInstance3D = MeshInstance3D.new()
	var cyl: CylinderMesh = CylinderMesh.new()
	cyl.top_radius = 0.06
	cyl.bottom_radius = 0.08
	cyl.height = 2.4
	var pole_mat: StandardMaterial3D = StandardMaterial3D.new()
	pole_mat.albedo_color = Color(0.2, 0.22, 0.25)
	pole_mat.metallic = 0.4
	pole_mat.roughness = 0.5
	pole_mesh.mesh = cyl
	pole_mesh.material_override = pole_mat
	pole_mesh.position.y = 1.2
	lamp.add_child(pole_mesh)
	
	# Foco de luz cálida
	var bulb_mesh: MeshInstance3D = MeshInstance3D.new()
	var bulb_box: BoxMesh = BoxMesh.new()
	bulb_box.size = Vector3(0.3, 0.25, 0.3)
	var bulb_mat: StandardMaterial3D = StandardMaterial3D.new()
	bulb_mat.albedo_color = Color(1.0, 0.95, 0.6)
	bulb_mat.emission_enabled = true
	bulb_mat.emission = Color(1.0, 0.9, 0.5)
	bulb_mat.emission_energy_multiplier = 1.5
	bulb_mesh.mesh = bulb_box
	bulb_mesh.material_override = bulb_mat
	bulb_mesh.position.y = 2.45
	lamp.add_child(bulb_mesh)
	
	props_container.add_child(lamp)

func create_lowpoly_tree(pos: Vector3) -> void:
	var tree: Node3D = Node3D.new()
	tree.position = pos
	
	# Tronco
	var trunk: MeshInstance3D = MeshInstance3D.new()
	var cyl: CylinderMesh = CylinderMesh.new()
	cyl.top_radius = 0.15
	cyl.bottom_radius = 0.22
	cyl.height = 1.4
	var t_mat: StandardMaterial3D = StandardMaterial3D.new()
	t_mat.albedo_color = Color(0.42, 0.28, 0.16)
	t_mat.roughness = 0.8
	trunk.mesh = cyl
	trunk.material_override = t_mat
	trunk.position.y = 0.7
	tree.add_child(trunk)
	
	# Copa inferior
	var foliage1: MeshInstance3D = MeshInstance3D.new()
	var cone1: CylinderMesh = CylinderMesh.new()
	cone1.top_radius = 0.05
	cone1.bottom_radius = 1.1
	cone1.height = 1.4
	var f_mat1: StandardMaterial3D = StandardMaterial3D.new()
	f_mat1.albedo_color = Color(0.18, 0.52, 0.22)
	f_mat1.roughness = 0.7
	foliage1.mesh = cone1
	foliage1.material_override = f_mat1
	foliage1.position.y = 1.8
	tree.add_child(foliage1)

	# Copa superior
	var foliage2: MeshInstance3D = MeshInstance3D.new()
	var cone2: CylinderMesh = CylinderMesh.new()
	cone2.top_radius = 0.02
	cone2.bottom_radius = 0.75
	cone2.height = 1.2
	var f_mat2: StandardMaterial3D = StandardMaterial3D.new()
	f_mat2.albedo_color = Color(0.24, 0.62, 0.26)
	f_mat2.roughness = 0.7
	foliage2.mesh = cone2
	foliage2.material_override = f_mat2
	foliage2.position.y = 2.6
	tree.add_child(foliage2)

	props_container.add_child(tree)

func create_fountain_monument(pos: Vector3) -> void:
	var monument: Node3D = Node3D.new()
	monument.position = pos
	
	# Base de la fuente
	var base: MeshInstance3D = MeshInstance3D.new()
	var cyl: CylinderMesh = CylinderMesh.new()
	cyl.top_radius = 0.9
	cyl.bottom_radius = 1.1
	cyl.height = 0.4
	var b_mat: StandardMaterial3D = StandardMaterial3D.new()
	b_mat.albedo_color = Color(0.78, 0.76, 0.70)
	base.mesh = cyl
	base.material_override = b_mat
	base.position.y = 0.2
	monument.add_child(base)
	
	# Obelisco / estatua central
	var obelisk: MeshInstance3D = MeshInstance3D.new()
	var cyl2: CylinderMesh = CylinderMesh.new()
	cyl2.top_radius = 0.15
	cyl2.bottom_radius = 0.35
	cyl2.height = 1.8
	var o_mat: StandardMaterial3D = StandardMaterial3D.new()
	o_mat.albedo_color = Color(0.85, 0.82, 0.75)
	obelisk.mesh = cyl2
	obelisk.material_override = o_mat
	obelisk.position.y = 1.2
	monument.add_child(obelisk)
	
	props_container.add_child(monument)

func setup_buildings() -> void:
	# 1. Parque Galilea (Constructora VIS) - Noreste
	var galilea = $Buildings/BuildingGalilea
	if galilea:
		galilea.position = Vector3(12.0, 0.55, -7.5)
		galilea.rotation_degrees.y = -90.0 # Mirando hacia la avenida oeste
		galilea.set_building(
			"parque_galilea",
			"[PROYECTO VIS CARTAGENA]",
			"Sala de Ventas: Parque Galilea",
			"¡Bienvenido a Parque Galilea! Nuestro proyecto VIS está diseñado para que con tus subsidios y un plan de cuotas de $700.000 logres tu casa propia en Cartagena.",
			Color(0.08, 0.45, 0.35),
			Color(0.12, 0.55, 0.42)
		)

	# 2. Comfenalco Cartagena (Caja de compensación) - Noroeste
	var comfenalco = $Buildings/BuildingComfenalco
	if comfenalco:
		comfenalco.position = Vector3(-12.0, 0.55, -7.5)
		comfenalco.rotation_degrees.y = 90.0 # Mirando hacia la avenida este
		comfenalco.set_building(
			"comfenalco",
			"[CAJA DE COMPENSACIÓN FAMILIAR]",
			"Caja Comfenalco Cartagena",
			"¡Hola! En Comfenalco Cartagena te asesoramos para postular al subsidio familiar de vivienda (hasta 30 SMMLV).",
			Color(0.12, 0.36, 0.78),
			Color(0.18, 0.48, 0.88)
		)

	# 3. Entidad Financiera (FNA y Bancos) - Suroeste
	var banco = $Buildings/BuildingBanco
	if banco:
		banco.position = Vector3(-12.0, 0.55, 7.5)
		banco.rotation_degrees.y = 90.0 # Mirando hacia la avenida este
		banco.set_building(
			"banco",
			"[CRÉDITO HIPOTECARIO & CESANTÍAS]",
			"Entidad Financiera: FNA y Bancos",
			"Te asesoramos en la Carta de Preaprobación de Crédito y en el traslado de tus Cesantías o Ahorro Voluntario (AVC).",
			Color(0.10, 0.22, 0.46),
			Color(0.85, 0.70, 0.18)
		)

	# 4. Sisbén IV y MinVivienda (Mi Casa Ya) - Sureste
	var sisben = $Buildings/BuildingSisben
	if sisben:
		sisben.position = Vector3(12.0, 0.55, 7.5)
		sisben.rotation_degrees.y = -90.0 # Mirando hacia la avenida oeste
		sisben.set_building(
			"sisben",
			"[GOBIERNO NACIONAL - MINVIVIENDA]",
			"Módulo Sisbén IV & Mi Casa Ya",
			"Verifica tu grupo del Sisbén (A1 a C8) para acceder al subsidio nacional Mi Casa Ya y activar la concurrencia con Comfenalco.",
			Color(0.85, 0.42, 0.15),
			Color(0.92, 0.52, 0.22)
		)

	# 5. Corvivienda (Alcaldía Distrital) - Sur centro
	var corvivienda = $Buildings/BuildingCorvivienda
	if corvivienda:
		corvivienda.position = Vector3(0.0, 0.55, 13.5)
		corvivienda.rotation_degrees.y = 180.0 # Mirando hacia el norte (Plaza)
		corvivienda.set_building(
			"corvivienda",
			"[ALCALDÍA DISTRITAL DE CARTAGENA]",
			"Corvivienda: Subsidio Mi Casa Va",
			"Conoce el subsidio distrital de Cartagena para hogares que sueñan con vivienda propia en la Heroica.",
			Color(0.78, 0.15, 0.18),
			Color(0.88, 0.72, 0.15)
		)
