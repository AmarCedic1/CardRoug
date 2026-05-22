extends Node
class_name TestRuleEngineActions

func test_field_monster_does_not_expose_hand_only_actions() -> void:
    var rule_engine: RuleEngine = RuleEngine.new()
    var card_instance: CardInstance = _create_card_instance("monster", DuelManager.CARD_ZONE_MONSTER)
    card_instance.face_up = true
    card_instance.has_changed_battle_position_this_turn = false

    var context: Dictionary = _default_context()
    var actions: Array[StringName] = rule_engine.get_available_actions(card_instance, context)

    assert(not actions.has(RuleEngine.ACTION_NORMAL_SUMMON), "Field card must not show normal summon.")
    assert(not actions.has(RuleEngine.ACTION_SET_MONSTER), "Field card must not show set monster.")
    assert(not actions.has(RuleEngine.ACTION_ACTIVATE_SPELL), "Field card must not show activate spell.")
    assert(not actions.has(RuleEngine.ACTION_SET_SPELL), "Field card must not show set spell.")

func test_phase_gating_blocks_normal_summon_outside_main_phase() -> void:
    var rule_engine: RuleEngine = RuleEngine.new()
    var card_instance: CardInstance = _create_card_instance("monster", DuelManager.CARD_ZONE_HAND)

    var context: Dictionary = _default_context()
    context[RuleEngine.CONTEXT_CURRENT_PHASE] = DuelManager.PHASE_BATTLE

    var actions: Array[StringName] = rule_engine.get_available_actions(card_instance, context)
    assert(not actions.has(RuleEngine.ACTION_NORMAL_SUMMON), "Normal summon must be blocked outside main phases.")
    assert(not actions.has(RuleEngine.ACTION_SET_MONSTER), "Set monster must be blocked outside main phases.")

func test_once_per_turn_gating_blocks_additional_normal_summon() -> void:
    var rule_engine: RuleEngine = RuleEngine.new()
    var card_instance: CardInstance = _create_card_instance("monster", DuelManager.CARD_ZONE_HAND)

    var context: Dictionary = _default_context()
    context[RuleEngine.CONTEXT_NORMAL_SUMMON_USED] = true

    var actions: Array[StringName] = rule_engine.get_available_actions(card_instance, context)
    assert(not actions.has(RuleEngine.ACTION_NORMAL_SUMMON), "Normal summon should be blocked after usage this turn.")
    assert(not actions.has(RuleEngine.ACTION_SET_MONSTER), "Set monster should be blocked after normal summon usage this turn.")

func test_monsters_cannot_be_played_in_draw_standby_battle_or_end_phase() -> void:
    var rule_engine: RuleEngine = RuleEngine.new()
    var card_instance: CardInstance = _create_card_instance("monster", DuelManager.CARD_ZONE_HAND)

    var blocked_phases: Array[StringName] = [
        DuelManager.PHASE_DRAW,
        DuelManager.PHASE_STANDBY,
        DuelManager.PHASE_BATTLE,
        DuelManager.PHASE_END,
    ]

    for phase_name: StringName in blocked_phases:
        var context: Dictionary = _default_context()
        context[RuleEngine.CONTEXT_CURRENT_PHASE] = phase_name

        var actions: Array[StringName] = rule_engine.get_available_actions(card_instance, context)
        assert(not actions.has(RuleEngine.ACTION_NORMAL_SUMMON), "Normal summon must be blocked in phase %s." % [String(phase_name)])
        assert(not actions.has(RuleEngine.ACTION_SET_MONSTER), "Set monster must be blocked in phase %s." % [String(phase_name)])

func test_set_spell_trap_activation_available_when_face_down_and_not_set_this_turn() -> void:
    var rule_engine: RuleEngine = RuleEngine.new()
    var card_instance: CardInstance = _create_card_instance("trap", DuelManager.CARD_ZONE_SPELL_TRAP)
    card_instance.face_up = false
    card_instance.was_set_this_turn = false
    card_instance.card_data["race"] = "Normal"

    var context: Dictionary = _default_context()
    var actions: Array[StringName] = rule_engine.get_available_actions(card_instance, context)
    assert(actions.has(RuleEngine.ACTION_ACTIVATE_SET_SPELL_TRAP), "Face-down set trap should be activatable on a later turn.")

func test_set_spell_trap_activation_blocked_when_set_this_turn() -> void:
    var rule_engine: RuleEngine = RuleEngine.new()
    var card_instance: CardInstance = _create_card_instance("trap", DuelManager.CARD_ZONE_SPELL_TRAP)
    card_instance.face_up = false
    card_instance.was_set_this_turn = true
    card_instance.card_data["race"] = "Normal"

    var context: Dictionary = _default_context()
    var actions: Array[StringName] = rule_engine.get_available_actions(card_instance, context)
    assert(not actions.has(RuleEngine.ACTION_ACTIVATE_SET_SPELL_TRAP), "Trap set this turn must not be activatable.")

func test_response_speed_blocks_non_counter_trap_when_chain_speed_is_three() -> void:
    var rule_engine: RuleEngine = RuleEngine.new()
    var card_instance: CardInstance = _create_card_instance("trap", DuelManager.CARD_ZONE_SPELL_TRAP)
    card_instance.face_up = false
    card_instance.was_set_this_turn = false
    card_instance.card_data["race"] = "Normal"

    var context: Dictionary = _default_context()
    context[RuleEngine.CONTEXT_CHAIN_IN_PROGRESS] = true
    context[RuleEngine.CONTEXT_IN_RESPONSE_WINDOW] = true
    context[RuleEngine.CONTEXT_CHAIN_MIN_RESPONSE_SPEED] = 3

    var actions: Array[StringName] = rule_engine.get_available_actions(card_instance, context)
    assert(not actions.has(RuleEngine.ACTION_ACTIVATE_SET_SPELL_TRAP), "Only counter traps should respond to chain speed 3.")

func test_declare_attack_only_in_battle_and_once_per_turn() -> void:
    var rule_engine: RuleEngine = RuleEngine.new()
    var card_instance: CardInstance = _create_card_instance("monster", DuelManager.CARD_ZONE_MONSTER)
    card_instance.face_up = true
    card_instance.battle_position = DuelManager.BATTLE_POSITION_ATTACK

    var battle_context: Dictionary = _default_context()
    battle_context[RuleEngine.CONTEXT_CURRENT_PHASE] = DuelManager.PHASE_BATTLE

    var battle_actions: Array[StringName] = rule_engine.get_available_actions(card_instance, battle_context)
    assert(battle_actions.has(RuleEngine.ACTION_DECLARE_ATTACK), "Declare attack should be available in battle phase for face-up attack-position monster.")

    card_instance.has_attacked_this_turn = true
    var after_attack_actions: Array[StringName] = rule_engine.get_available_actions(card_instance, battle_context)
    assert(not after_attack_actions.has(RuleEngine.ACTION_DECLARE_ATTACK), "Declare attack should be blocked after monster already attacked this turn.")

    card_instance.has_attacked_this_turn = false
    var main_phase_context: Dictionary = _default_context()
    main_phase_context[RuleEngine.CONTEXT_CURRENT_PHASE] = DuelManager.PHASE_MAIN_1
    var main_phase_actions: Array[StringName] = rule_engine.get_available_actions(card_instance, main_phase_context)
    assert(not main_phase_actions.has(RuleEngine.ACTION_DECLARE_ATTACK), "Declare attack must be unavailable outside battle phase.")

func _create_card_instance(card_type: String, zone_id: int) -> CardInstance:
    var card_instance: CardInstance = CardInstance.new()
    var card_data: Dictionary = {
        "id": 2000,
        "name": "RuleTestCard",
        "card_type": card_type,
    }
    card_instance.setup(card_data, DuelManager.OWNER_PLAYER, zone_id)
    return card_instance

func _default_context() -> Dictionary:
    var context: Dictionary = {
        RuleEngine.CONTEXT_ACTIVE_OWNER: DuelManager.OWNER_PLAYER,
        RuleEngine.CONTEXT_IS_PLAYER_TURN: true,
        RuleEngine.CONTEXT_CURRENT_PHASE: DuelManager.PHASE_MAIN_1,
        RuleEngine.CONTEXT_NORMAL_SUMMON_USED: false,
        RuleEngine.CONTEXT_HAS_FREE_MONSTER_ZONE: true,
        RuleEngine.CONTEXT_HAS_FREE_SPELL_TRAP_ZONE: true,
        RuleEngine.CONTEXT_CHAIN_IN_PROGRESS: false,
        RuleEngine.CONTEXT_IN_RESPONSE_WINDOW: false,
        RuleEngine.CONTEXT_CHAIN_MIN_RESPONSE_SPEED: 1,
    }
    return context
