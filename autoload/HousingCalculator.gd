extends Node

## HousingCalculator.gd
## Motor de cálculo financiero para subsidios y cierre financiero VIS en Colombia / Cartagena.
## Basado en la normativa de MinVivienda, Comfenalco Cartagena, Corvivienda y crédito hipotecario/FNA.

# Valor del Salario Mínimo Mensual Legal Vigente (referencia Colombia)
var smmlv: float = 1423500.0

# Perfil del usuario / hogar
var household_income: float = 2000000.0 # Ingresos mensuales del hogar en COP
var sisben_group: String = "B4" # A1-A5, B1-B7, C1-C8, C9-D20
var is_affiliated_to_caja: bool = true # Comfenalco / Comfamiliar
var has_own_property: bool = false # Si ya tiene casa, no aplica a subsidios
var current_savings: float = 2000000.0 # Ahorro programado o cesantías acumuladas
var monthly_installments_saved: float = 0.0 # Ahorro acumulado pagando cuotas a constructora

# Parámetros del proyecto de vivienda (Ej. Parque Galilea)
var project_name: String = "Parque Galilea (Cartagena)"
var house_price_in_smmlv: float = 135.0 # Típico VIS: 135 a 150 SMMLV
var initial_fee_percentage: float = 0.30 # 30% de cuota inicial
var installment_monthly_payment: float = 700000.0 # Cuota mensual acordada (ej. $700.000 COP)
var installment_months: int = 10 # Cantidad de meses de preventa pactados

# Estados de aprobación de las entidades
var caja_approved: bool = false
var micasaya_approved: bool = false
var micasava_approved: bool = false
var bank_credit_approved: bool = false

# Señal emitida cuando cambian los cálculos
signal calculations_updated(summary: Dictionary)

func _ready() -> void:
	emit_calculations()

## Convierte un monto en pesos colombianos a SMMLV
func cop_to_smmlv(amount: float) -> float:
	return amount / smmlv

## Convierte SMMLV a pesos colombianos
func smmlv_to_cop(smmlv_units: float) -> float:
	return smmlv_units * smmlv

## Formatea moneda a formato colombiano ($ 1.423.500)
func format_cop(amount: float) -> String:
	var rounded: int = int(round(amount))
	var s: String = str(abs(rounded))
	var res: String = ""
	var count: int = 0
	for i in range(s.length() - 1, -1, -1):
		res = s[i] + res
		count += 1
		if count % 3 == 0 and i > 0:
			res = "." + res
	if rounded < 0:
		return "-$" + res
	return "$" + res

## Calcula el subsidio de la Caja de Compensación (Comfenalco / Comfamiliar)
## Hasta 2 SMMLV = 30 SMMLV de subsidio
## De 2 a 4 SMMLV = 20 SMMLV de subsidio
## Más de 4 SMMLV = 0
func calculate_caja_subsidy() -> float:
	if not is_affiliated_to_caja or has_own_property:
		return 0.0
	var income_in_smmlv: float = cop_to_smmlv(household_income)
	if income_in_smmlv <= 2.0:
		return smmlv_to_cop(30.0)
	elif income_in_smmlv <= 4.0:
		return smmlv_to_cop(20.0)
	return 0.0

## Verifica si el grupo de Sisbén aplica a Mi Casa Ya
func is_sisben_eligible() -> bool:
	if has_own_property:
		return false
	var letter: String = sisben_group.substr(0, 1).to_upper()
	if letter == "A" or letter == "B":
		return true
	if letter == "C":
		var num: int = sisben_group.substr(1).to_int()
		return num <= 8 # C1 a C8 aplica
	return false

## Calcula el subsidio de Mi Casa Ya (MinVivienda)
## Con Concurrencia (si ya tiene subsidio de Caja y gana <= 2 SMMLV) = 20 SMMLV
## Sin concurrencia (solo Mi Casa Ya) = 30 SMMLV
func calculate_micasaya_subsidy() -> float:
	if not is_sisben_eligible():
		return 0.0
	
	var caja_sub: float = calculate_caja_subsidy()
	var income_in_smmlv: float = cop_to_smmlv(household_income)
	
	# Concurrencia de subsidios:
	if is_affiliated_to_caja and caja_sub > 0.0 and income_in_smmlv <= 2.0:
		return smmlv_to_cop(20.0) # Subsidio complementario de Mi Casa Ya
	else:
		return smmlv_to_cop(30.0)

## Subsidio distrital de Cartagena (Corvivienda - Mi Casa Va)
## Aplica como apoyo complementario distrital (aprox 10 SMMLV)
func calculate_micasava_subsidy() -> float:
	if has_own_property:
		return 0.0
	if is_sisben_eligible():
		return smmlv_to_cop(10.0)
	return 0.0

## Total de subsidios potenciales sumados por Concurrencia
func calculate_total_potential_subsidies() -> float:
	var total: float = 0.0
	var caja: float = calculate_caja_subsidy()
	var mcy: float = calculate_micasaya_subsidy()
	var mcva: float = calculate_micasava_subsidy()
	
	total = caja + mcy + mcva
	return total

## Capacidad máxima de cuota mensual que permite un banco/FNA (máx 30% del ingreso)
func calculate_max_monthly_credit_fee() -> float:
	return household_income * 0.35

## Estimación de capacidad de crédito hipotecario (a 20 años / 240 meses)
func estimate_bank_credit_capacity() -> float:
	var max_fee: float = calculate_max_monthly_credit_fee()
	# Factor financiero estimado (aprox. 1 millon prestado = $9.500 cuota mensual con subsidio de tasa)
	var estimated_loan: float = (max_fee / 9500.0) * 1000000.0
	return estimated_loan

## Resumen completo del Cierre Financiero para el proyecto (Parque Galilea)
func get_financial_summary() -> Dictionary:
	var total_price: float = smmlv_to_cop(house_price_in_smmlv)
	var initial_fee_required: float = total_price * initial_fee_percentage
	
	# Total que el usuario aporta pagando cuotas en preventa (ej. 10 x $700.000)
	var total_installments_to_pay: float = installment_monthly_payment * float(installment_months)
	
	# Aportes propios
	var own_funds: float = current_savings + total_installments_to_pay
	
	# Subsidios
	var caja_sub: float = calculate_caja_subsidy()
	var mcy_sub: float = calculate_micasaya_subsidy()
	var mcva_sub: float = calculate_micasava_subsidy()
	var total_subsidies: float = caja_sub + mcy_sub + mcva_sub
	
	# Crédito requerido después de cuota inicial y subsidios
	var remaining_for_credit: float = total_price - own_funds - total_subsidies
	if remaining_for_credit < 0:
		remaining_for_credit = 0.0
		
	var credit_capacity: float = estimate_bank_credit_capacity()
	var can_afford_credit: bool = credit_capacity >= remaining_for_credit
	
	# Cierre financiero total
	var total_resources: float = own_funds + total_subsidies + remaining_for_credit
	var deficit: float = total_price - (own_funds + total_subsidies + min(credit_capacity, remaining_for_credit))
	if deficit < 0:
		deficit = 0.0
		
	var is_financially_closed: bool = deficit <= 1000.0 and can_afford_credit
	
	var data: Dictionary = {
		"total_price": total_price,
		"initial_fee_required": initial_fee_required,
		"installment_monthly_payment": installment_monthly_payment,
		"installment_months": installment_months,
		"total_installments_to_pay": total_installments_to_pay,
		"current_savings": current_savings,
		"own_funds": own_funds,
		"caja_subsidy": caja_sub,
		"mcy_subsidy": mcy_sub,
		"mcva_subsidy": mcva_sub,
		"total_subsidies": total_subsidies,
		"is_concurrencia_active": (caja_sub > 0 and mcy_sub > 0),
		"remaining_for_credit": remaining_for_credit,
		"credit_capacity": credit_capacity,
		"can_afford_credit": can_afford_credit,
		"deficit": deficit,
		"is_financially_closed": is_financially_closed
	}
	return data

func emit_calculations() -> void:
	emit_signal("calculations_updated", get_financial_summary())
