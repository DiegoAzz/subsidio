extends Node3D

## CityMap3D.gd
## Escena principal de la mini-ciudad en 3D (Maqueta de Cartagena).
## Configura los 5 pabellones interactivos, el entorno 3D y la interfaz 2D superpuesta.

@onready var player: CharacterBody3D = $Player3D
@onready var hud: CanvasLayer = $HUD

func _ready() -> void:
	setup_buildings()

func setup_buildings() -> void:
	# 1. Parque Galilea (Constructora)
	var galilea = $Buildings/BuildingGalilea
	if galilea:
		galilea.set_building(
			"parque_galilea",
			"Sala de Ventas: Parque Galilea",
			"¡Bienvenido a Parque Galilea! Nuestro proyecto VIS está diseñado para que con tus subsidios y un plan de cuotas de $700.000 logres tu casa propia en Cartagena.",
			Color(0.12, 0.48, 0.38),
			Color(0.85, 0.35, 0.2)
		)

	# 2. Comfenalco Cartagena (Caja de compensación)
	var comfenalco = $Buildings/BuildingComfenalco
	if comfenalco:
		comfenalco.set_building(
			"comfenalco",
			"Caja Comfenalco Cartagena",
			"¡Hola! En Comfenalco Cartagena te asesoramos para postular al subsidio familiar de vivienda (hasta 30 SMMLV).",
			Color(0.15, 0.35, 0.75),
			Color(0.2, 0.45, 0.85)
		)

	# 3. FNA & Bancos (Financiera)
	var banco = $Buildings/BuildingBanco
	if banco:
		banco.set_building(
			"fna_banco",
			"Entidad Financiera: FNA y Bancos",
			"Te ayudamos a tramitar la Carta de Preaprobado y trasladar tus cesantías o ahorro voluntario.",
			Color(0.18, 0.24, 0.36),
			Color(0.3, 0.4, 0.5)
		)

	# 4. Sisbén & Mi Casa Ya (Nacional)
	var sisben = $Buildings/BuildingSisben
	if sisben:
		sisben.set_building(
			"micasaya",
			"Módulo Sisbén IV & Mi Casa Ya",
			"Revisa tu grupo del Sisbén (A1 a C8) para acceder al subsidio concurrente del Gobierno Nacional.",
			Color(0.85, 0.5, 0.1),
			Color(0.9, 0.65, 0.2)
		)

	# 5. Corvivienda (Distrital)
	var corvivienda = $Buildings/BuildingCorvivienda
	if corvivienda:
		corvivienda.set_building(
			"corvivienda",
			"Corvivienda: Mi Casa Va",
			"Conoce las convocatorias distritales de la Alcaldía de Cartagena para subsidios complementarios.",
			Color(0.75, 0.2, 0.2),
			Color(0.85, 0.75, 0.2)
		)
