extends Resource
class_name EnemyData

@export_group("Identidade")
@export var enemy_name: String = "Inimigo"
@export var is_boss: bool = false
@export var icon: String = "🐛"

@export_group("Atributos de Combate")
@export var max_hp: float = 40.0
@export var base_speed: float = 3.0
@export var attack_damage: float = 6.0
@export var attack_interval: float = 1.0
@export var xp_reward: int = 15
@export var is_flying: bool = false
@export var armor_rating: float = 0.0 # 0.0 a 1.0 (ex: 0.30 para Besouro)

@export_group("Drop de Recursos")
@export_range(0.0, 1.0) var drop_chance_total: float = 0.18
@export var fixed_drop_item: String = "" # Usado por chefes (ex: "FAIRY_TEAR", "LADYBUG_EGG")
