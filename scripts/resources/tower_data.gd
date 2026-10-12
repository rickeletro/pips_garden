extends Resource
class_name TowerData

@export_group("Identidade & Nível")
@export var tower_name: String = "Torre de Gravetos"
@export var level: int = 1
@export var specialization: int = 0 # 0: None, 1: Thorn Cannon, 2: Sap Catapult

@export_group("Combate")
@export var damage_per_shot: float = 15.0
@export var attack_interval: float = 1.25 # segundos por disparo (0.8 tiros/s)
@export var range_radius: float = 4.5
@export var shots_per_burst: int = 1
@export var armor_pierce: float = 0.0 # 0.0 a 1.0 (50% no Canhão 3A)
@export var splash_radius: float = 0.0 # 2.5m na Catapulta 3B
@export var slow_percent: float = 0.0 # 15% na Catapulta 3B

@export_group("Economia")
@export var cost_twigs: int = 3
@export var cost_gears: int = 2
@export var preventive_repair_twigs: int = 2
@export var rebuild_twigs: int = 4
@export var rebuild_gears: int = 1
