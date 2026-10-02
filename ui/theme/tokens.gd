class_name Tokens extends RefCounted

# ==========================================
# PALETA OFICIAL - JARDIM MIÚDO (DESIGN.md)
# ==========================================
const VERDE_MUSGO: Color = Color("#4F6B3A")        # Painéis, grama escura
const VERDE_FOLHA: Color = Color("#8FB05A")        # Grama, destaques positivos
const MARROM_CASCA: Color = Color("#5A3E2B")       # Molduras, madeira
const CREME_PERGAMINHO: Color = Color("#F3E6C4")   # Texto e fundos claros
const DOURADO_LUZ: Color = Color("#E8B94A")        # Destaque, seleção, luz
const RUIVO_COBRE: Color = Color("#B5471F")        # Cabelo da heroína, alertas quentes
const RUIVO: Color = RUIVO_COBRE                   # Alias
const PALHA: Color = DOURADO_LUZ                   # Cinto vegetal e fibras
const LATAO_ENGRENAGEM: Color = Color("#C9953C")   # Engrenagens e metal
const VENENO_VERDE: Color = Color("#7ED957")       # Veneno corrosivo
const VENENO_AMBAR: Color = Color("#E39A2D")       # Veneno lento (mel)
const VENENO_VIOLETA: Color = Color("#8E7CC3")     # Veneno em névoa
const PERIGO: Color = Color("#C8402F")             # Vida baixa, recurso insuficiente

# Transparências padronizadas
const OPACIDADE_PAINEL: float = 0.85
const COR_FUNDO_PAINEL: Color = Color(0.31, 0.42, 0.23, OPACIDADE_PAINEL) # VERDE_MUSGO a 85%
const COR_FUNDO_SLOT: Color = Color(0.20, 0.27, 0.15, 0.92)

# ==========================================
# MÉTRICAS E ESPAÇAMENTOS
# ==========================================
const SLOT_SIZE: Vector2 = Vector2(48, 48)
const SLOT_ICON_SIZE: Vector2 = Vector2(28, 28)
const SLOT_SPACING: int = 8
const CORNER_RADIUS_PANEL: int = 10
const CORNER_RADIUS_SLOT: int = 8
const BORDER_WIDTH_PANEL: int = 2
const BORDER_WIDTH_SLOT: int = 2
const SAFE_MARGIN_RATIO: float = 0.04 # 4% das bordas livres

# ==========================================
# TIPOGRAFIA
# ==========================================
const FONT_SIZE_SLOT_KEY: int = 10
const FONT_SIZE_SLOT_LABEL: int = 11
const FONT_SIZE_BODY: int = 13
const FONT_SIZE_TITLE: int = 18
const FONT_SIZE_BANNER: int = 22
const OUTLINE_SIZE_SMALL: int = 3
const OUTLINE_SIZE_MEDIUM: int = 5
const OUTLINE_COLOR: Color = Color(0.12, 0.08, 0.05, 0.9)

# ==========================================
# GERADORES DE ESTILO (PADRÃO TÉCNICO)
# ==========================================
static func make_panel_style(bg: Color = COR_FUNDO_PAINEL, border: Color = MARROM_CASCA, radius: int = CORNER_RADIUS_PANEL) -> StyleBoxFlat:
	var sb = StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_width_left = BORDER_WIDTH_PANEL
	sb.border_width_top = BORDER_WIDTH_PANEL
	sb.border_width_right = BORDER_WIDTH_PANEL
	sb.border_width_bottom = BORDER_WIDTH_PANEL
	sb.border_color = border
	sb.corner_radius_top_left = radius
	sb.corner_radius_top_right = radius
	sb.corner_radius_bottom_right = radius
	sb.corner_radius_bottom_left = radius
	sb.shadow_color = Color(0, 0, 0, 0.35)
	sb.shadow_size = 4
	return sb

static func make_slot_style(border_color: Color = MARROM_CASCA, bg_color: Color = COR_FUNDO_SLOT) -> StyleBoxFlat:
	var sb = StyleBoxFlat.new()
	sb.bg_color = bg_color
	sb.border_width_left = BORDER_WIDTH_SLOT
	sb.border_width_top = BORDER_WIDTH_SLOT
	sb.border_width_right = BORDER_WIDTH_SLOT
	sb.border_width_bottom = BORDER_WIDTH_SLOT
	sb.border_color = border_color
	sb.corner_radius_top_left = CORNER_RADIUS_SLOT
	sb.corner_radius_top_right = CORNER_RADIUS_SLOT
	sb.corner_radius_bottom_right = CORNER_RADIUS_SLOT
	sb.corner_radius_bottom_left = CORNER_RADIUS_SLOT
	return sb

static func make_progress_bar_style(fill_color: Color, radius: int = 4) -> StyleBoxFlat:
	var sb = StyleBoxFlat.new()
	sb.bg_color = fill_color
	sb.corner_radius_top_left = radius
	sb.corner_radius_top_right = radius
	sb.corner_radius_bottom_right = radius
	sb.corner_radius_bottom_left = radius
	return sb
