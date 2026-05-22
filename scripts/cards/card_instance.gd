extends RefCounted
class_name CardInstance

enum Owner {
    PLAYER,
    ENEMY,
}

enum Zone {
    DECK,
    HAND,
    MONSTER,
    SPELL_TRAP,
    GRAVEYARD,
    BANISHED,
    EXTRA,
}

enum BattlePosition {
    ATTACK,
    DEFENSE,
}

enum SummonKind {
    NONE,
    NORMAL,
    SPECIAL,
    FLIP,
}

var card_data: Dictionary = {}
var owner: int = Owner.PLAYER
var current_zone: int = Zone.DECK
var previous_zone: int = Zone.DECK
var zone_slot_index: int = -1

var face_up: bool = true
var battle_position: int = BattlePosition.ATTACK

var summon_kind_this_turn: int = SummonKind.NONE
var was_normal_summoned: bool = false
var was_special_summoned: bool = false
var has_changed_battle_position_this_turn: bool = false
var has_attacked_this_turn: bool = false
var was_set_this_turn: bool = false
var has_activated_this_turn: bool = false

func setup(data: Dictionary, card_owner: int, start_zone: int, slot_index: int = -1) -> void:
    card_data = data.duplicate(true)
    owner = card_owner
    current_zone = start_zone
    previous_zone = start_zone
    zone_slot_index = slot_index

func set_zone(new_zone: int, slot_index: int = -1) -> void:
    previous_zone = current_zone
    current_zone = new_zone
    zone_slot_index = slot_index

func is_monster() -> bool:
    return str(card_data.get("card_type", "")) == "monster"

func is_spell_or_trap() -> bool:
    var card_type: String = str(card_data.get("card_type", ""))
    return card_type == "spell" or card_type == "trap"

func get_spell_speed() -> int:
    if not is_spell_or_trap():
        return 0

    var card_type: String = str(card_data.get("card_type", ""))
    var speed_hint: String = str(card_data.get("race", "")).to_lower()

    if card_type == "trap":
        if speed_hint == "counter":
            return 3
        return 2

    if speed_hint == "quick-play":
        return 2

    return 1

func is_persistent_spell_trap() -> bool:
    if not is_spell_or_trap():
        return false

    var speed_hint: String = str(card_data.get("race", "")).to_lower()
    return speed_hint == "continuous" or speed_hint == "equip" or speed_hint == "field"

func mark_set_this_turn() -> void:
    was_set_this_turn = true

func mark_activated_this_turn() -> void:
    has_activated_this_turn = true

func mark_normal_summoned() -> void:
    summon_kind_this_turn = SummonKind.NORMAL
    was_normal_summoned = true
    was_special_summoned = false

func mark_special_summoned() -> void:
    summon_kind_this_turn = SummonKind.SPECIAL
    was_special_summoned = true

func mark_flip_summoned() -> void:
    summon_kind_this_turn = SummonKind.FLIP

func reset_turn_temporary_flags() -> void:
    summon_kind_this_turn = SummonKind.NONE
    was_normal_summoned = false
    was_special_summoned = false
    has_changed_battle_position_this_turn = false
    has_attacked_this_turn = false
    was_set_this_turn = false
    has_activated_this_turn = false
