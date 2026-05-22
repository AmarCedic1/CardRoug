extends Control
class_name CardUI

const CARD_BACK_TEXTURE: Texture2D = preload("res://assets/generated/card_back_default_frame_0.png")

var card_data: Dictionary = {}
var face_up: bool = true
var in_attack_position: bool = true
var _front_texture: Texture2D = null

var _selection_active: bool = false
var _selection_targetable: bool = false
var _chain_reactive_highlight: bool = false

const OUTLINE_NONE: Color = Color(0.0, 0.0, 0.0, 0.0)
const OUTLINE_TARGETABLE: Color = Color(0.46, 1.0, 0.58, 0.92)
const OUTLINE_CHAIN_REACTIVE: Color = Color(1.0, 0.91, 0.5, 0.9)
const OUTLINE_BORDER_WIDTH: float = 3.0

func _ready() -> void:
    set_mouse_filter(Control.MOUSE_FILTER_STOP)

func _draw() -> void:
    var outline_color: Color = _get_outline_color()
    if outline_color.a <= 0.0:
        return

    var draw_rect_area: Rect2 = Rect2(Vector2.ZERO, size)
    draw_rect(draw_rect_area, outline_color, false, OUTLINE_BORDER_WIDTH)

func set_target_selection_state(is_active: bool, is_targetable: bool) -> void:
    _selection_active = is_active
    _selection_targetable = is_targetable
    _refresh_highlight_visuals()

func set_chain_reactive_highlight(is_enabled: bool) -> void:
    _chain_reactive_highlight = is_enabled
    _refresh_highlight_visuals()

func _get_outline_color() -> Color:
    if _selection_active:
        if _selection_targetable:
            return OUTLINE_TARGETABLE
        return OUTLINE_NONE

    if _chain_reactive_highlight:
        return OUTLINE_CHAIN_REACTIVE

    return OUTLINE_NONE

func _refresh_highlight_visuals() -> void:
    if _selection_active and not _selection_targetable:
        self_modulate = Color(0.82, 0.82, 0.82, 1.0)
    else:
        self_modulate = Color(1.0, 1.0, 1.0, 1.0)

    queue_redraw()

func set_card(data: Dictionary) -> void:
    card_data = data

    _front_texture = null
    if data.has("image_path"):
        var loaded_texture: Resource = load(str(data["image_path"]))
        if loaded_texture is Texture2D:
            _front_texture = loaded_texture as Texture2D

    _refresh_visual_state()

func set_face_up(is_face_up: bool) -> void:
    face_up = is_face_up
    _refresh_visual_state()

func update_stats() -> void:
    _refresh_stats_text()

func _refresh_visual_state() -> void:
    var artwork_node: TextureRect = $Artwork as TextureRect
    if face_up:
        artwork_node.texture = _front_texture
    else:
        artwork_node.texture = CARD_BACK_TEXTURE

    _refresh_stats_text()

func _refresh_stats_text() -> void:
    var stats_node: Label = $Stats as Label

    if not face_up:
        stats_node.text = ""
        return

    if not card_data.has("card_type"):
        stats_node.text = ""
        return

    if str(card_data["card_type"]) != "monster":
        stats_node.text = ""
        return

    if in_attack_position:
        stats_node.text = str(card_data.get("atk", ""))
    else:
        stats_node.text = str(card_data.get("def", ""))

func apply_display_size(card_size: Vector2) -> void:
    var safe_size: Vector2 = Vector2(maxf(8.0, card_size.x), maxf(8.0, card_size.y))

    set_anchors_preset(Control.PRESET_TOP_LEFT)
    custom_minimum_size = safe_size
    size = safe_size

    var artwork_node: TextureRect = $Artwork as TextureRect
    artwork_node.offset_left = 0.0
    artwork_node.offset_top = 0.0
    artwork_node.offset_right = safe_size.x
    artwork_node.offset_bottom = safe_size.y

    var stats_node: Label = $Stats as Label
    var stats_height: float = clampf(safe_size.y * 0.22, 22.0, 56.0)
    stats_node.offset_left = 0.0
    stats_node.offset_right = safe_size.x
    stats_node.offset_top = safe_size.y - stats_height
    stats_node.offset_bottom = safe_size.y

    queue_redraw()

func _gui_input(event: InputEvent) -> void:
    var mouse_event: InputEventMouseButton = event as InputEventMouseButton
    if mouse_event == null:
        return

    if mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_LEFT:
        var duel_manager: DuelManager = get_tree().root.get_node_or_null("main/DuelManager") as DuelManager
        if duel_manager != null:
            duel_manager.on_card_clicked(self)

func _on_mouse_entered() -> void:
    if not face_up:
        return

    var hover: Node = get_tree().root.get_node_or_null("main/HoverPreviewPanel")
    if hover != null:
        hover.show_card(card_data)

func _on_mouse_exited() -> void:
    var hover: Node = get_tree().root.get_node_or_null("main/HoverPreviewPanel")
    if hover != null:
        hover.hide_card()
# Füge unten in CardUI hinzu (oder ersetze vorhandene Varianten)

func set_attack_position() -> void:
    in_attack_position = true
    _refresh_stats_text()

func set_defense_position() -> void:
    in_attack_position = false
    _refresh_stats_text()

func set_facedown() -> void:
    set_face_up(false)

func flip_face_up() -> void:
    set_face_up(true)
