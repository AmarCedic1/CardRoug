extends RefCounted
class_name RuleEngine

const ACTION_NORMAL_SUMMON: StringName = &"normal_summon"
const ACTION_SET_MONSTER: StringName = &"set_monster"
const ACTION_ACTIVATE_SPELL: StringName = &"activate_spell"
const ACTION_ACTIVATE_SET_SPELL_TRAP: StringName = &"activate_set_spell_trap"
const ACTION_SET_SPELL: StringName = &"set_spell"
const ACTION_POS_CHANGE: StringName = &"position_change"
const ACTION_FLIP_SUMMON: StringName = &"flip_summon"
const ACTION_DECLARE_ATTACK: StringName = &"declare_attack"

const CONTEXT_ACTIVE_OWNER: StringName = &"active_owner"
const CONTEXT_IS_PLAYER_TURN: StringName = &"is_player_turn"
const CONTEXT_CURRENT_PHASE: StringName = &"current_phase"
const CONTEXT_NORMAL_SUMMON_USED: StringName = &"normal_summon_used"
const CONTEXT_HAS_FREE_MONSTER_ZONE: StringName = &"has_free_monster_zone"
const CONTEXT_HAS_FREE_SPELL_TRAP_ZONE: StringName = &"has_free_spell_trap_zone"
const CONTEXT_OPPONENT_HAS_MONSTERS: StringName = &"opponent_has_monsters"
const CONTEXT_HAS_ATTACK_TARGET: StringName = &"has_attack_target"
const CONTEXT_CHAIN_IN_PROGRESS: StringName = &"chain_in_progress"
const CONTEXT_CHAIN_MIN_RESPONSE_SPEED: StringName = &"chain_min_response_speed"
const CONTEXT_IN_RESPONSE_WINDOW: StringName = &"in_response_window"

const PHASE_MAIN_1: StringName = &"MAIN1"
const PHASE_MAIN_2: StringName = &"MAIN2"
const PHASE_BATTLE: StringName = &"BATTLE"

const CARD_ZONE_HAND: int = 1
const CARD_ZONE_MONSTER: int = 2
const CARD_ZONE_SPELL_TRAP: int = 3
const BATTLE_POSITION_ATTACK: int = 0

func get_available_actions(card: RefCounted, context: Dictionary) -> Array[StringName]:
    var actions: Array[StringName] = []
    if card == null:
        return actions

    if can_normal_summon(card, context):
        actions.append(ACTION_NORMAL_SUMMON)
    if can_set_monster(card, context):
        actions.append(ACTION_SET_MONSTER)
    if can_activate_spell(card, context):
        actions.append(ACTION_ACTIVATE_SPELL)
    if can_activate_set_spell_trap(card, context):
        actions.append(ACTION_ACTIVATE_SET_SPELL_TRAP)
    if can_set_spell(card, context):
        actions.append(ACTION_SET_SPELL)
    if can_change_battle_position(card, context):
        actions.append(ACTION_POS_CHANGE)
    if can_flip_summon(card, context):
        actions.append(ACTION_FLIP_SUMMON)
    if can_declare_attack(card, context):
        actions.append(ACTION_DECLARE_ATTACK)

    return actions

func can_normal_summon(card: RefCounted, context: Dictionary) -> bool:
    if not _can_use_actions(card, context):
        return false
    if card.current_zone != CARD_ZONE_HAND:
        return false
    if not card.is_monster():
        return false
    if not _is_main_phase(context):
        return false
    if _is_chain_locked(context):
        return false
    if bool(context.get(CONTEXT_NORMAL_SUMMON_USED, false)):
        return false
    return bool(context.get(CONTEXT_HAS_FREE_MONSTER_ZONE, false))

func can_set_monster(card: RefCounted, context: Dictionary) -> bool:
    if not _can_use_actions(card, context):
        return false
    if card.current_zone != CARD_ZONE_HAND:
        return false
    if not card.is_monster():
        return false
    if not _is_main_phase(context):
        return false
    if _is_chain_locked(context):
        return false
    if bool(context.get(CONTEXT_NORMAL_SUMMON_USED, false)):
        return false
    return bool(context.get(CONTEXT_HAS_FREE_MONSTER_ZONE, false))

func can_activate_spell(card: RefCounted, context: Dictionary) -> bool:
    if not _can_use_actions(card, context):
        return false
    if card.current_zone != CARD_ZONE_HAND:
        return false
    if not card.is_spell_or_trap():
        return false
    if not _is_main_phase(context):
        return false
    if _is_chain_locked(context):
        return false
    return bool(context.get(CONTEXT_HAS_FREE_SPELL_TRAP_ZONE, false))

func can_activate_set_spell_trap(card: RefCounted, context: Dictionary) -> bool:
    if not _can_use_actions(card, context):
        return false
    if card.current_zone != CARD_ZONE_SPELL_TRAP:
        return false
    if not card.is_spell_or_trap():
        return false
    if card.face_up:
        return false
    if bool(card.was_set_this_turn):
        return false

    var card_speed: int = _get_card_spell_speed(card)
    if card_speed <= 0:
        return false

    var in_response_window: bool = bool(context.get(CONTEXT_IN_RESPONSE_WINDOW, false))
    if in_response_window:
        var min_speed: int = maxi(2, int(context.get(CONTEXT_CHAIN_MIN_RESPONSE_SPEED, 1)))
        return card_speed >= min_speed

    if not _is_main_phase(context):
        return false
    if _is_chain_locked(context):
        return false
    return true

func can_set_spell(card: RefCounted, context: Dictionary) -> bool:
    if not _can_use_actions(card, context):
        return false
    if card.current_zone != CARD_ZONE_HAND:
        return false
    if not card.is_spell_or_trap():
        return false
    if not _is_main_phase(context):
        return false
    if _is_chain_locked(context):
        return false
    return bool(context.get(CONTEXT_HAS_FREE_SPELL_TRAP_ZONE, false))

func can_change_battle_position(card: RefCounted, context: Dictionary) -> bool:
    if not _can_use_actions(card, context):
        return false
    if card.current_zone != CARD_ZONE_MONSTER:
        return false
    if not _is_main_phase(context):
        return false
    if _is_chain_locked(context):
        return false
    if not card.face_up:
        return false
    return not card.has_changed_battle_position_this_turn

func can_flip_summon(card: RefCounted, context: Dictionary) -> bool:
    if not _can_use_actions(card, context):
        return false
    if card.current_zone != CARD_ZONE_MONSTER:
        return false
    if not _is_main_phase(context):
        return false
    if _is_chain_locked(context):
        return false
    if card.face_up:
        return false
    if card.was_normal_summoned:
        return false
    if card.was_special_summoned:
        return false
    return true

func can_declare_attack(card: RefCounted, context: Dictionary) -> bool:
    if not _can_use_actions(card, context):
        return false
    if card.current_zone != CARD_ZONE_MONSTER:
        return false
    if not card.is_monster():
        return false
    if _is_chain_locked(context):
        return false
    if StringName(context.get(CONTEXT_CURRENT_PHASE, StringName())) != PHASE_BATTLE:
        return false
    if not card.face_up:
        return false
    if card.battle_position != BATTLE_POSITION_ATTACK:
        return false
    if card.has_attacked_this_turn:
        return false

    var opponent_has_monsters: bool = bool(context.get(CONTEXT_OPPONENT_HAS_MONSTERS, false))
    var has_attack_target: bool = bool(context.get(CONTEXT_HAS_ATTACK_TARGET, true))
    if opponent_has_monsters and not has_attack_target:
        return false

    return true

func _can_use_actions(card: RefCounted, context: Dictionary) -> bool:
    var active_owner: int = int(context.get(CONTEXT_ACTIVE_OWNER, 0))
    return card.owner == active_owner

func _is_main_phase(context: Dictionary) -> bool:
    var phase: StringName = StringName(context.get(CONTEXT_CURRENT_PHASE, StringName()))
    return phase == PHASE_MAIN_1 or phase == PHASE_MAIN_2

func _is_chain_locked(context: Dictionary) -> bool:
    return bool(context.get(CONTEXT_CHAIN_IN_PROGRESS, false)) and not bool(context.get(CONTEXT_IN_RESPONSE_WINDOW, false))

func _get_card_spell_speed(card: RefCounted) -> int:
    if card == null:
        return 0

    if card.has_method("get_spell_speed"):
        var speed_variant: Variant = card.call("get_spell_speed")
        if speed_variant is int:
            return int(speed_variant)

    var card_data: Dictionary = card.card_data as Dictionary
    var card_type: String = str(card_data.get("card_type", ""))
    var race_hint: String = str(card_data.get("race", "")).to_lower()

    if card_type == "trap":
        if race_hint == "counter":
            return 3
        return 2
    if race_hint == "quick-play":
        return 2

    return 1
