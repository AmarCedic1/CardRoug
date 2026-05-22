extends Control
class_name ActionMenu

var target_card: CardUI = null
var _ignore_next_outside_click: bool = false
var _available_actions: Array[StringName] = []

@onready var _normal_button: Button = $NormalButton as Button
@onready var _set_button: Button = $SetButton as Button
@onready var _activate_button: Button = $ActivateButton as Button
@onready var _set_spell_button: Button = $SetSpellButton as Button
@onready var _pos_change_button: Button = $PosChangeButton as Button
@onready var _flip_button: Button = $FlipSummonButton as Button
@onready var _attack_button: Button = $AttackButton as Button

const MENU_Z_INDEX: int = 5000

func _ready() -> void:
    top_level = true
    z_as_relative = false
    z_index = mini(MENU_Z_INDEX, RenderingServer.CANVAS_ITEM_Z_MAX)

func set_available_actions(actions: Array[StringName]) -> void:
    _available_actions = actions.duplicate()
    _sync_buttons()

func _sync_buttons() -> void:
    _normal_button.visible = _available_actions.has(DuelManager.ACTION_NORMAL_SUMMON)
    _set_button.visible = _available_actions.has(DuelManager.ACTION_SET_MONSTER)
    _activate_button.visible = _available_actions.has(DuelManager.ACTION_ACTIVATE_SPELL) or _available_actions.has(DuelManager.ACTION_ACTIVATE_SET_SPELL_TRAP)
    _set_spell_button.visible = _available_actions.has(DuelManager.ACTION_SET_SPELL)
    _pos_change_button.visible = _available_actions.has(DuelManager.ACTION_POS_CHANGE)
    _flip_button.visible = _available_actions.has(DuelManager.ACTION_FLIP_SUMMON)
    _attack_button.visible = _available_actions.has(DuelManager.ACTION_DECLARE_ATTACK)

func open(card: CardUI, pos: Vector2) -> void:
    if _available_actions.is_empty():
        close()
        return

    target_card = card
    global_position = pos
    visible = true
    move_to_front()
    _ignore_next_outside_click = true
    call_deferred("_enable_outside_click_close")

func close() -> void:
    visible = false
    target_card = null

func _enable_outside_click_close() -> void:
    _ignore_next_outside_click = false

func _get_duel_manager() -> DuelManager:
    return get_tree().root.get_node_or_null("main/DuelManager") as DuelManager

func _has_valid_target_and_manager() -> bool:
    if target_card == null or not is_instance_valid(target_card):
        push_warning("Keine gültige Zielkarte im ActionMenu.")
        close()
        return false

    var duel_manager: DuelManager = _get_duel_manager()
    if duel_manager == null:
        push_warning("DuelManager nicht gefunden.")
        close()
        return false

    return true

func _is_action_currently_available(action: StringName, duel_manager: DuelManager) -> bool:
    var current_actions: Array[StringName] = duel_manager.get_available_actions(target_card)
    return current_actions.has(action)

func _on_NormalButton_pressed() -> void:
    if not _has_valid_target_and_manager():
        return

    var duel_manager: DuelManager = _get_duel_manager()
    if duel_manager == null or not _is_action_currently_available(DuelManager.ACTION_NORMAL_SUMMON, duel_manager):
        close()
        return

    duel_manager.normal_summon(target_card)
    close()

func _on_SetButton_pressed() -> void:
    if not _has_valid_target_and_manager():
        return

    var duel_manager: DuelManager = _get_duel_manager()
    if duel_manager == null or not _is_action_currently_available(DuelManager.ACTION_SET_MONSTER, duel_manager):
        close()
        return

    duel_manager.set_summon(target_card)
    close()

func _on_ActivateButton_pressed() -> void:
    if not _has_valid_target_and_manager():
        return

    var duel_manager: DuelManager = _get_duel_manager()
    if duel_manager == null:
        close()
        return

    var use_set_activation: bool = _is_action_currently_available(DuelManager.ACTION_ACTIVATE_SET_SPELL_TRAP, duel_manager)
    var use_hand_activation: bool = _is_action_currently_available(DuelManager.ACTION_ACTIVATE_SPELL, duel_manager)

    if use_set_activation:
        duel_manager.activate_set_spell_trap(target_card)
        close()
        return

    if use_hand_activation:
        duel_manager.activate_spell(target_card)
        close()
        return

    close()

func _on_SetSpellButton_pressed() -> void:
    if not _has_valid_target_and_manager():
        return

    var duel_manager: DuelManager = _get_duel_manager()
    if duel_manager == null or not _is_action_currently_available(DuelManager.ACTION_SET_SPELL, duel_manager):
        close()
        return

    duel_manager.set_spell(target_card)
    close()
func _on_PosChangeButton_pressed() -> void:
    if not _has_valid_target_and_manager():
        return

    var dm: DuelManager = _get_duel_manager()
    if dm == null or not _is_action_currently_available(DuelManager.ACTION_POS_CHANGE, dm):
        close()
        return

    dm.position_change(target_card)
    close()

func _on_FlipSummonButton_pressed() -> void:
    if not _has_valid_target_and_manager():
        return

    var dm: DuelManager = _get_duel_manager()
    if dm == null or not _is_action_currently_available(DuelManager.ACTION_FLIP_SUMMON, dm):
        close()
        return

    dm.flip_summon(target_card)
    close()

func _on_AttackButton_pressed() -> void:
    if not _has_valid_target_and_manager():
        return

    var dm: DuelManager = _get_duel_manager()
    if dm == null or not _is_action_currently_available(DuelManager.ACTION_DECLARE_ATTACK, dm):
        close()
        return

    dm.declare_attack(target_card)
    close()

func _unhandled_input(event: InputEvent) -> void:
    if not visible or _ignore_next_outside_click:
        return

    var mouse_event: InputEventMouseButton = event as InputEventMouseButton
    if mouse_event == null:
        return

    if mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_LEFT:
        var menu_rect: Rect2 = Rect2(global_position, size)
        var mouse_position: Vector2 = get_global_mouse_position()
        if not menu_rect.has_point(mouse_position):
            close()


func _on_pos_change_button_pressed() -> void:
    _on_PosChangeButton_pressed()

func _on_flip_summon_button_pressed() -> void:
    _on_FlipSummonButton_pressed()

func _on_attack_button_pressed() -> void:
    _on_AttackButton_pressed()
