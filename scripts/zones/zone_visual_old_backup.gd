extends Control
class_name ZoneVisualBackup

@export var zone_name: String = ""
@export var is_player: bool = true
@export var show_zone_graphic: bool = false
@export var show_zone_label: bool = false
@export var player_fill_color: Color = Color(0.15, 0.45, 1.0, 0.16)
@export var enemy_fill_color: Color = Color(1.0, 0.35, 0.2, 0.2)
@export var border_color: Color = Color(1.0, 1.0, 1.0, 0.9)
@export var border_width: float = 2.0
@export var show_zone_border: bool = false
@export var overlay_z_index: int = 100

@export_group("Card Layout")
@export var use_custom_card_size: bool = false
@export var custom_card_size: Vector2 = Vector2(120.0, 170.0)
@export var custom_card_offset: Vector2 = Vector2.ZERO

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    z_as_relative = false
    z_index = overlay_z_index
    var duel_manager_node: Node = get_tree().root.get_node_or_null("main/DuelManager")
    if duel_manager_node == null:
        push_warning("DuelManager nicht gefunden unter main/DuelManager")
        return
    if zone_name == "":
        push_warning("Zone hat keinen Namen!")
        return
    duel_manager_node.register_zone(zone_name, self, is_player)
    queue_redraw()


func _notification(what: int) -> void:
    if what == NOTIFICATION_RESIZED:
        queue_redraw()


func _draw() -> void:
    if not show_zone_graphic:
        return

    var zone_rect: Rect2 = Rect2(Vector2.ZERO, size)
    var fill_color: Color = player_fill_color if is_player else enemy_fill_color
    draw_rect(zone_rect, fill_color, true)
    if show_zone_border:
        draw_rect(zone_rect, border_color, false, border_width)

    if show_zone_label and zone_name != "":
        var label_font: Font = ThemeDB.fallback_font
        if label_font != null:
            var label_size: int = 12
            var label_position: Vector2 = Vector2(6.0, 16.0)
            draw_string(label_font, label_position, zone_name, HORIZONTAL_ALIGNMENT_LEFT, -1.0, label_size, Color(1.0, 1.0, 1.0, 0.8))

func get_card_size(default_size: Vector2) -> Vector2:
    if not use_custom_card_size:
        return default_size

    var clamped_width: float = maxf(8.0, custom_card_size.x)
    var clamped_height: float = maxf(8.0, custom_card_size.y)
    return Vector2(clamped_width, clamped_height)

func get_card_offset() -> Vector2:
    return custom_card_offset
