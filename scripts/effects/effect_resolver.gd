extends RefCounted
class_name EffectResolver

const OP_NONE: StringName = &"none"
const OP_DRAW_OWNER: StringName = &"draw_owner"
const OP_DAMAGE_OPPONENT: StringName = &"damage_opponent"
const OP_DAMAGE_OPPONENT_PER_MONSTER: StringName = &"damage_opponent_per_monster"
const OP_DAMAGE_OWNER: StringName = &"damage_owner"
const OP_TREMENDOUS_FIRE: StringName = &"tremendous_fire"
const OP_GAIN_LP_OWNER: StringName = &"gain_lp_owner"
const OP_DESTROY_ONE_OPPONENT_MONSTER: StringName = &"destroy_one_opponent_monster"
const OP_DESTROY_ALL_MONSTERS: StringName = &"destroy_all_monsters"
const OP_DESTROY_ALL_OPPONENT_MONSTERS: StringName = &"destroy_all_opponent_monsters"
const OP_DESTROY_ONE_OPPONENT_SPELL_TRAP: StringName = &"destroy_one_opponent_spell_trap"
const OP_SET_ONE_OPPONENT_MONSTER_FACE_DOWN: StringName = &"set_one_opponent_monster_face_down"
const OP_SET_ONE_OPPONENT_MONSTER_DEFENSE: StringName = &"set_one_opponent_monster_defense"
const OP_NEGATE_PREVIOUS_CHAIN_LINK: StringName = &"negate_previous_chain_link"

const CARD_NAME_KEY: StringName = &"name"
const CARD_EFFECT_TEXT_KEY: StringName = &"effect_text"

const NUMBER_WORD_RULES: Array[Dictionary] = [
    {"token": "ten", "value": 10},
    {"token": "nine", "value": 9},
    {"token": "eight", "value": 8},
    {"token": "seven", "value": 7},
    {"token": "six", "value": 6},
    {"token": "five", "value": 5},
    {"token": "four", "value": 4},
    {"token": "three", "value": 3},
    {"token": "two", "value": 2},
    {"token": "one", "value": 1},
]

var _exact_effects_by_name: Dictionary = {
    "pot of greed": _build_effect_spec(OP_DRAW_OWNER, 2),
    "graceful charity": _build_effect_spec(OP_DRAW_OWNER, 3),
    "ookazi": _build_effect_spec(OP_DAMAGE_OPPONENT, 800),
    "fissure": _build_effect_spec(OP_DESTROY_ONE_OPPONENT_MONSTER, 1),
    "smashing ground": _build_effect_spec(OP_DESTROY_ONE_OPPONENT_MONSTER, 1),
    "dark hole": _build_effect_spec(OP_DESTROY_ALL_MONSTERS, 0),
    "raigeki": _build_effect_spec(OP_DESTROY_ALL_MONSTERS, 0),
    "mystical space typhoon": _build_effect_spec(OP_DESTROY_ONE_OPPONENT_SPELL_TRAP, 1),
    "dust tornado": _build_effect_spec(OP_DESTROY_ONE_OPPONENT_SPELL_TRAP, 1),
    "book of moon": _build_effect_spec(OP_SET_ONE_OPPONENT_MONSTER_FACE_DOWN, 1),
    "enemy controller": _build_effect_spec(OP_SET_ONE_OPPONENT_MONSTER_DEFENSE, 1),
    "just desserts": _build_effect_spec(OP_DAMAGE_OPPONENT_PER_MONSTER, 500),
    "tremendous fire": _build_effect_spec(OP_TREMENDOUS_FIRE, 0),
    "goblin thief": _build_effect_spec(OP_GAIN_LP_OWNER, 500),
    "magic jammer": _build_effect_spec(OP_NEGATE_PREVIOUS_CHAIN_LINK, 0),
    "seven tools of the bandit": _build_effect_spec(OP_NEGATE_PREVIOUS_CHAIN_LINK, 0),
    "magic drain": _build_effect_spec(OP_NEGATE_PREVIOUS_CHAIN_LINK, 0),
    "solemn judgment": _build_effect_spec(OP_NEGATE_PREVIOUS_CHAIN_LINK, 0, true),
}

func create_effect_for_card(card_instance: CardInstance, source_action: StringName) -> Dictionary:
    if card_instance == null:
        return {
            "card_instance": null,
            "source_action": source_action,
            "operation": OP_NONE,
            "amount": 0,
            "half_lp_cost": false,
        }

    var card_data: Dictionary = card_instance.card_data as Dictionary
    var card_name: String = str(card_data.get(CARD_NAME_KEY, "")).to_lower()
    var effect_text: String = str(card_data.get(CARD_EFFECT_TEXT_KEY, "")).to_lower()
    var effect_spec: Dictionary = _resolve_effect_spec(card_name, effect_text)

    return {
        "card_instance": card_instance,
        "source_action": source_action,
        "operation": StringName(effect_spec.get("operation", OP_NONE)),
        "amount": int(effect_spec.get("amount", 0)),
        "half_lp_cost": bool(effect_spec.get("half_lp_cost", false)),
    }

func resolve_effect(effect: Dictionary, duel_manager: DuelManager, current_link_index: int = -1) -> bool:
    if effect.is_empty() or duel_manager == null:
        return false

    var card_instance: CardInstance = effect.get("card_instance") as CardInstance
    if card_instance == null:
        return false

    if not duel_manager.is_card_still_on_field(card_instance):
        return false

    var operation: StringName = StringName(effect.get("operation", OP_NONE))
    var amount: int = int(effect.get("amount", 0))

    if operation == OP_DRAW_OWNER:
        return duel_manager.draw_cards_for_owner(card_instance.owner, amount)

    if operation == OP_DAMAGE_OPPONENT:
        var opponent_owner: int = duel_manager.get_opponent_owner(card_instance.owner)
        duel_manager.apply_life_point_damage(opponent_owner, amount)
        return true

    if operation == OP_DAMAGE_OPPONENT_PER_MONSTER:
        var opponent_for_count: int = duel_manager.get_opponent_owner(card_instance.owner)
        var opponent_monster_count: int = _count_field_monsters_for_owner(duel_manager, opponent_for_count)
        if opponent_monster_count <= 0:
            return false
        duel_manager.apply_life_point_damage(opponent_for_count, amount * opponent_monster_count)
        return true

    if operation == OP_DAMAGE_OWNER:
        duel_manager.apply_life_point_damage(card_instance.owner, amount)
        return true

    if operation == OP_TREMENDOUS_FIRE:
        var opponent_for_fire: int = duel_manager.get_opponent_owner(card_instance.owner)
        duel_manager.apply_life_point_damage(opponent_for_fire, 1000)
        duel_manager.apply_life_point_damage(card_instance.owner, 500)
        return true

    if operation == OP_GAIN_LP_OWNER:
        duel_manager.gain_life_points(card_instance.owner, amount)
        return true

    if operation == OP_DESTROY_ONE_OPPONENT_MONSTER:
        var target_monster: CardInstance = duel_manager.get_first_monster_for_owner(duel_manager.get_opponent_owner(card_instance.owner))
        if target_monster == null:
            return false
        return duel_manager.destroy_card_instance(target_monster, &"effect")

    if operation == OP_DESTROY_ALL_MONSTERS:
        var all_monsters: Array[CardInstance] = duel_manager.get_all_field_monsters()
        var destroyed_any_monster: bool = false
        for monster: CardInstance in all_monsters:
            if monster == null:
                continue
            if duel_manager.destroy_card_instance(monster, &"effect"):
                destroyed_any_monster = true
        return destroyed_any_monster

    if operation == OP_DESTROY_ALL_OPPONENT_MONSTERS:
        var opponent_owner_for_wipe: int = duel_manager.get_opponent_owner(card_instance.owner)
        var field_monsters: Array[CardInstance] = duel_manager.get_all_field_monsters()
        var destroyed_any_opponent_monster: bool = false
        for field_monster: CardInstance in field_monsters:
            if field_monster == null:
                continue
            if int(field_monster.owner) != opponent_owner_for_wipe:
                continue
            if duel_manager.destroy_card_instance(field_monster, &"effect"):
                destroyed_any_opponent_monster = true
        return destroyed_any_opponent_monster

    if operation == OP_DESTROY_ONE_OPPONENT_SPELL_TRAP:
        var target_spell_trap: CardInstance = duel_manager.get_first_spell_trap_for_owner(duel_manager.get_opponent_owner(card_instance.owner))
        if target_spell_trap == null:
            return false
        return duel_manager.destroy_card_instance(target_spell_trap, &"effect")

    if operation == OP_SET_ONE_OPPONENT_MONSTER_FACE_DOWN:
        var target_flip_down: CardInstance = duel_manager.get_first_monster_for_owner(duel_manager.get_opponent_owner(card_instance.owner))
        if target_flip_down == null:
            return false
        return duel_manager.set_monster_face_down(target_flip_down)

    if operation == OP_SET_ONE_OPPONENT_MONSTER_DEFENSE:
        var target_defense: CardInstance = duel_manager.get_first_monster_for_owner(duel_manager.get_opponent_owner(card_instance.owner))
        if target_defense == null:
            return false
        return duel_manager.set_monster_to_defense(target_defense)

    if operation == OP_NEGATE_PREVIOUS_CHAIN_LINK:
        var should_pay_half_lp: bool = bool(effect.get("half_lp_cost", false))
        if should_pay_half_lp:
            var owner_lp: int = duel_manager.get_life_points(card_instance.owner)
            var lp_cost: int = int(ceili(float(owner_lp) / 2.0))
            duel_manager.apply_life_point_damage(card_instance.owner, lp_cost)
        return duel_manager.negate_next_chain_link_from(current_link_index)

    return true

func should_send_to_grave_after_resolve(card_instance: CardInstance) -> bool:
    if card_instance == null:
        return false
    if not card_instance.is_spell_or_trap():
        return false

    return not card_instance.is_persistent_spell_trap()

func get_activation_speed(card_instance: CardInstance) -> int:
    if card_instance == null:
        return 0
    return card_instance.get_spell_speed()

func _resolve_effect_spec(card_name: String, effect_text: String) -> Dictionary:
    if _exact_effects_by_name.has(card_name):
        var exact_spec_variant: Variant = _exact_effects_by_name[card_name]
        if exact_spec_variant is Dictionary:
            var exact_spec: Dictionary = exact_spec_variant as Dictionary
            return exact_spec.duplicate(true) as Dictionary

    var text_spec: Dictionary = _parse_effect_text(effect_text)
    if not text_spec.is_empty():
        return text_spec

    return _build_effect_spec(OP_NONE, 0)

func _parse_effect_text(effect_text: String) -> Dictionary:
    if effect_text.is_empty():
        return {}

    var text: String = effect_text.to_lower()

    if text.find("pay half your life points") >= 0 and text.find("negate") >= 0:
        return _build_effect_spec(OP_NEGATE_PREVIOUS_CHAIN_LINK, 0, true)

    if text.find("negate") >= 0 and text.find("activation") >= 0:
        return _build_effect_spec(OP_NEGATE_PREVIOUS_CHAIN_LINK, 0)

    if text.find("for each monster on your opponent") >= 0 and text.find("inflict") >= 0:
        var per_monster_amount: int = _extract_first_number_after_keyword(text, "inflict")
        if per_monster_amount > 0:
            return _build_effect_spec(OP_DAMAGE_OPPONENT_PER_MONSTER, per_monster_amount)

    if text.find("draw") >= 0 and text.find("card") >= 0:
        var draw_amount: int = _extract_first_number_after_keyword(text, "draw")
        if draw_amount <= 0:
            draw_amount = 1
        return _build_effect_spec(OP_DRAW_OWNER, draw_amount)

    if text.find("increase your life points by") >= 0 or (text.find("gain") >= 0 and text.find("life point") >= 0):
        var gain_amount: int = _extract_first_number(text)
        if gain_amount > 0:
            return _build_effect_spec(OP_GAIN_LP_OWNER, gain_amount)

    if text.find("inflict") >= 0 and (text.find("to your opponent") >= 0 or text.find("opponent's life points") >= 0):
        var burn_amount: int = _extract_first_number_after_keyword(text, "inflict")
        if burn_amount <= 0:
            burn_amount = _extract_first_number(text)
        if burn_amount > 0:
            return _build_effect_spec(OP_DAMAGE_OPPONENT, burn_amount)

    if text.find("destroy all monsters on the field") >= 0:
        return _build_effect_spec(OP_DESTROY_ALL_MONSTERS, 0)

    if text.find("destroy all monsters your opponent controls") >= 0:
        return _build_effect_spec(OP_DESTROY_ALL_OPPONENT_MONSTERS, 0)

    if text.find("destroy 1 monster your opponent controls") >= 0 or text.find("destroy one monster your opponent controls") >= 0:
        return _build_effect_spec(OP_DESTROY_ONE_OPPONENT_MONSTER, 1)

    var has_destroy_spell_trap_text: bool = text.find("destroy 1 spell or trap") >= 0 or text.find("destroy one spell or trap") >= 0 or text.find("destroy 1 spell/trap") >= 0
    if has_destroy_spell_trap_text and text.find("opponent") >= 0:
        return _build_effect_spec(OP_DESTROY_ONE_OPPONENT_SPELL_TRAP, 1)

    if text.find("face-down defense position") >= 0:
        return _build_effect_spec(OP_SET_ONE_OPPONENT_MONSTER_FACE_DOWN, 1)

    if text.find("to defense position") >= 0 and text.find("monster") >= 0:
        return _build_effect_spec(OP_SET_ONE_OPPONENT_MONSTER_DEFENSE, 1)

    return {}

func _extract_first_number_after_keyword(text: String, keyword: String) -> int:
    var keyword_index: int = text.find(keyword)
    if keyword_index < 0:
        return _extract_first_number(text)

    var start_index: int = keyword_index + keyword.length()
    if start_index >= text.length():
        return 0

    var tail_text: String = text.substr(start_index, text.length() - start_index)
    return _extract_first_number(tail_text)

func _extract_first_number(text: String) -> int:
    var digit_text: String = ""
    var collecting_digits: bool = false

    for char_index: int in range(text.length()):
        var character: String = text.substr(char_index, 1)
        var is_digit: bool = character >= "0" and character <= "9"
        if is_digit:
            digit_text += character
            collecting_digits = true
            continue

        if character == "," and collecting_digits:
            continue

        if collecting_digits:
            break

    if not digit_text.is_empty():
        return int(digit_text)

    var normalized_text: String = " " + text.replace(".", " ").replace(",", " ").replace(";", " ").replace(":", " ") + " "
    for rule: Dictionary in NUMBER_WORD_RULES:
        var token: String = str(rule.get("token", ""))
        var value: int = int(rule.get("value", 0))
        if token.is_empty() or value <= 0:
            continue
        if normalized_text.find(" " + token + " ") >= 0:
            return value

    return 0

func _count_field_monsters_for_owner(duel_manager: DuelManager, owner_id: int) -> int:
    var all_monsters: Array[CardInstance] = duel_manager.get_all_field_monsters()
    var count: int = 0
    for monster: CardInstance in all_monsters:
        if monster == null:
            continue
        if int(monster.owner) != owner_id:
            continue
        count += 1
    return count

func _build_effect_spec(operation: StringName, amount: int, half_lp_cost: bool = false) -> Dictionary:
    return {
        "operation": operation,
        "amount": amount,
        "half_lp_cost": half_lp_cost,
    }
