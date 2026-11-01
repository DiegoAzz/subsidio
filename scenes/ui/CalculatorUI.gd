extends Control

## CalculatorUI.gd
## Panel interactivo para simular el Cierre Financiero real de vivienda VIS en Cartagena.
## Permite al ciudadano mover sliders de salario, seleccionar subsidios y ver cómo pagar la cuota inicial.

@onready var income_slider: HSlider = $Panel/VBox/Content/LeftCol/IncomeSlider
@onready var income_label: Label = $Panel/VBox/Content/LeftCol/IncomeVal
@onready var sisben_option: OptionButton = $Panel/VBox/Content/LeftCol/SisbenOption
@onready var caja_checkbox: CheckBox = $Panel/VBox/Content/LeftCol/CajaCheck
@onready var savings_spin: SpinBox = $Panel/VBox/Content/LeftCol/SavingsSpin
@onready var fee_spin: SpinBox = $Panel/VBox/Content/LeftCol/FeeSpin
@onready var months_spin: SpinBox = $Panel/VBox/Content/LeftCol/MonthsSpin

# Etiquetas de Resultados
@onready var total_price_lbl: Label = $Panel/VBox/Content/RightCol/TotalPriceVal
@onready var initial_fee_lbl: Label = $Panel/VBox/Content/RightCol/InitialFeeVal
@onready var installments_lbl: Label = $Panel/VBox/Content/RightCol/InstallmentsVal
@onready var caja_sub_lbl: Label = $Panel/VBox/Content/RightCol/CajaSubVal
@onready var mcy_sub_lbl: Label = $Panel/VBox/Content/RightCol/MCYSubVal
@onready var mcva_sub_lbl: Label = $Panel/VBox/Content/RightCol/MCVASubVal
@onready var concurrencia_badge: Label = $Panel/VBox/Content/RightCol/ConcurrenciaBadge
@onready var credit_needed_lbl: Label = $Panel/VBox/Content/RightCol/CreditVal
@onready var credit_cap_lbl: Label = $Panel/VBox/Content/RightCol/CreditCapVal
@onready var result_banner: Label = $Panel/VBox/ResultBanner

func _ready() -> void:
	# Configurar opciones de Sisbén
	sisben_option.clear()
	sisben_option.add_item("Grupo A (Pobreza extrema - A1 a A5)", 0)
	sisben_option.add_item("Grupo B (Pobreza moderada - B1 a B7)", 1)
	sisben_option.add_item("Grupo C (Vulnerable - C1 a C8)", 2)
	sisben_option.add_item("Grupo C alto o D (No aplica a subsidio)", 3)
	sisben_option.select(1) # B por defecto
	
	income_slider.value = HousingCalculator.household_income
	caja_checkbox.button_pressed = HousingCalculator.is_affiliated_to_caja
	savings_spin.value = HousingCalculator.current_savings
	fee_spin.value = HousingCalculator.installment_monthly_payment
	months_spin.value = HousingCalculator.installment_months
	
	# Conexiones
	income_slider.value_changed.connect(_on_income_changed)
	sisben_option.item_selected.connect(_on_sisben_changed)
	caja_checkbox.toggled.connect(_on_caja_toggled)
	savings_spin.value_changed.connect(_on_savings_changed)
	fee_spin.value_changed.connect(_on_fee_changed)
	months_spin.value_changed.connect(_on_months_changed)
	
	$Panel/VBox/Header/CloseBtn.pressed.connect(func(): visible = false)
	update_all_calculations()

func _on_income_changed(val: float) -> void:
	HousingCalculator.household_income = val
	income_label.text = HousingCalculator.format_cop(val)
	update_all_calculations()

func _on_sisben_changed(idx: int) -> void:
	match idx:
		0: HousingCalculator.sisben_group = "A2"
		1: HousingCalculator.sisben_group = "B4"
		2: HousingCalculator.sisben_group = "C5"
		3: HousingCalculator.sisben_group = "D1"
	update_all_calculations()

func _on_caja_toggled(pressed: bool) -> void:
	HousingCalculator.is_affiliated_to_caja = pressed
	update_all_calculations()

func _on_savings_changed(val: float) -> void:
	HousingCalculator.current_savings = val
	update_all_calculations()

func _on_fee_changed(val: float) -> void:
	HousingCalculator.installment_monthly_payment = val
	update_all_calculations()

func _on_months_changed(val: float) -> void:
	HousingCalculator.installment_months = int(val)
	update_all_calculations()

func update_all_calculations() -> void:
	var s: Dictionary = HousingCalculator.get_financial_summary()
	
	income_label.text = HousingCalculator.format_cop(HousingCalculator.household_income)
	total_price_lbl.text = HousingCalculator.format_cop(s["total_price"])
	initial_fee_lbl.text = HousingCalculator.format_cop(s["initial_fee_required"])
	installments_lbl.text = "%s (%d cuotas de %s)" % [
		HousingCalculator.format_cop(s["total_installments_to_pay"]),
		s["installment_months"],
		HousingCalculator.format_cop(s["installment_monthly_payment"])
	]
	
	caja_sub_lbl.text = HousingCalculator.format_cop(s["caja_subsidy"])
	mcy_sub_lbl.text = HousingCalculator.format_cop(s["mcy_subsidy"])
	mcva_sub_lbl.text = HousingCalculator.format_cop(s["mcva_subsidy"])
	
	concurrencia_badge.visible = s["is_concurrencia_active"]
	
	credit_needed_lbl.text = HousingCalculator.format_cop(s["remaining_for_credit"])
	credit_cap_lbl.text = "Capacidad estimada banco: " + HousingCalculator.format_cop(s["credit_capacity"])
	
	if s["is_financially_closed"]:
		result_banner.text = "★ ¡CIERRE FINANCIERO VIABLE! Cumples con cuota inicial, subsidios y crédito bancario."
		result_banner.modulate = Color(0.2, 0.95, 0.4)
	else:
		var deficit_str: String = HousingCalculator.format_cop(s["deficit"])
		result_banner.text = "Faltante para cerrar el proyecto: %s (Ajusta cuotas mensuales o busca mayor plazo)." % deficit_str
		result_banner.modulate = Color(1.0, 0.45, 0.3)
	
	HousingCalculator.emit_calculations()
