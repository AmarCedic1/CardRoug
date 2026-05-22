extends Node
class_name TestChainEffects

func test_chain_response_trap_resolves_before_normal_spell() -> void:
    var duel_manager: DuelManager = _build_test_duel_manager()

    var player_spell: CardInstance = _create_card_instance({
        "id": 3001,
        "name": "Ookazi",
        "card_type": "spell",
        "race": "Normal",
    }, DuelManager.OWNER_PLAYER, DuelManager.CARD_ZONE_HAND)
    var enemy_trap: CardInstance = _create_card_instance({
        "id": 3002,
        "name": "Goblin Thief",
        "card_type": "trap",
        "race": "Normal",
    }, DuelManager.OWNER_ENEMY, DuelManager.CARD_ZONE_SPELL_TRAP, 0)
    enemy_trap.face_up = false
    enemy_trap.was_set_this_turn = false

    var player_hand: Array = duel_manager.player_state[DuelManager.ZONE_KEY_HAND] as Array
    player_hand.append(player_spell)

    var enemy_spell_slots: Array = duel_manager.enemy_state[DuelManager.ZONE_KEY_SPELL_TRAP] as Array
    enemy_spell_slots[0] = enemy_trap

    var success: bool = duel_manager.action_resolver.execute_action(RuleEngine.ACTION_ACTIVATE_SPELL, null, player_spell, duel_manager)

    assert(success, "Initial spell activation should resolve successfully.")
    assert(player_spell.current_zone == DuelManager.CARD_ZONE_GRAVEYARD, "Activated normal spell must end in graveyard.")
    assert(enemy_trap.current_zone == DuelManager.CARD_ZONE_GRAVEYARD, "Chained trap must end in graveyard after resolution.")

    var enemy_lp: int = duel_manager.get_life_points(DuelManager.OWNER_ENEMY)
    var player_lp: int = duel_manager.get_life_points(DuelManager.OWNER_PLAYER)
    assert(enemy_lp == 7700, "Enemy LP should gain 500 then lose 800 due to reverse chain resolution.")
    assert(player_lp == 8000, "Player LP should remain unchanged in this chain scenario.")

func test_trap_set_this_turn_cannot_chain() -> void:
    var duel_manager: DuelManager = _build_test_duel_manager()

    var player_spell: CardInstance = _create_card_instance({
        "id": 3003,
        "name": "Ookazi",
        "card_type": "spell",
        "race": "Normal",
    }, DuelManager.OWNER_PLAYER, DuelManager.CARD_ZONE_HAND)
    var enemy_trap: CardInstance = _create_card_instance({
        "id": 3004,
        "name": "Goblin Thief",
        "card_type": "trap",
        "race": "Normal",
    }, DuelManager.OWNER_ENEMY, DuelManager.CARD_ZONE_SPELL_TRAP, 0)
    enemy_trap.face_up = false
    enemy_trap.was_set_this_turn = true

    var player_hand: Array = duel_manager.player_state[DuelManager.ZONE_KEY_HAND] as Array
    player_hand.append(player_spell)

    var enemy_spell_slots: Array = duel_manager.enemy_state[DuelManager.ZONE_KEY_SPELL_TRAP] as Array
    enemy_spell_slots[0] = enemy_trap

    var success: bool = duel_manager.action_resolver.execute_action(RuleEngine.ACTION_ACTIVATE_SPELL, null, player_spell, duel_manager)

    assert(success, "Activation should still resolve even if opponent cannot chain.")
    assert(player_spell.current_zone == DuelManager.CARD_ZONE_GRAVEYARD, "Activated spell should go to graveyard.")
    assert(enemy_trap.current_zone == DuelManager.CARD_ZONE_SPELL_TRAP, "Trap set this turn must stay set and not chain.")
    assert(duel_manager.get_life_points(DuelManager.OWNER_ENEMY) == 7200, "Enemy should only take 800 damage with no trap response.")

func test_trap_set_on_previous_turn_can_chain_on_opponent_turn() -> void:
    var duel_manager: DuelManager = _build_test_duel_manager()

    var enemy_spell: CardInstance = _create_card_instance({
        "id": 3005,
        "name": "Ookazi",
        "card_type": "spell",
        "race": "Normal",
    }, DuelManager.OWNER_ENEMY, DuelManager.CARD_ZONE_HAND)
    var player_trap: CardInstance = _create_card_instance({
        "id": 3006,
        "name": "Goblin Thief",
        "card_type": "trap",
        "race": "Normal",
    }, DuelManager.OWNER_PLAYER, DuelManager.CARD_ZONE_SPELL_TRAP, 0)
    player_trap.face_up = false
    player_trap.was_set_this_turn = true

    var enemy_hand: Array = duel_manager.enemy_state[DuelManager.ZONE_KEY_HAND] as Array
    enemy_hand.append(enemy_spell)

    var player_spell_slots: Array = duel_manager.player_state[DuelManager.ZONE_KEY_SPELL_TRAP] as Array
    player_spell_slots[0] = player_trap

    duel_manager.current_phase = DuelManager.PHASE_END
    duel_manager._on_next_phase_button_pressed()

    assert(not player_trap.was_set_this_turn, "Ending player turn should clear trap set-this-turn lock before opponent turn.")

    duel_manager.current_phase = DuelManager.PHASE_MAIN_1
    var enemy_activation_success: bool = duel_manager.action_resolver.execute_action(RuleEngine.ACTION_ACTIVATE_SPELL, null, enemy_spell, duel_manager)

    assert(enemy_activation_success, "Enemy spell activation should start chain successfully.")
    assert(duel_manager.chain_in_progress, "Chain should remain open while player response window is active.")
    assert(duel_manager.chain_response_window_owner == DuelManager.OWNER_PLAYER, "Player should receive the response window after enemy spell activation.")

    var response_actions: Array[StringName] = duel_manager.get_available_actions_for_card(player_trap)
    assert(response_actions.has(RuleEngine.ACTION_ACTIVATE_SET_SPELL_TRAP), "Trap set on previous turn should be chainable during opponent response window.")

func test_player_end_turn_clears_set_flags_for_traps() -> void:
    var duel_manager: DuelManager = _build_test_duel_manager()

    var player_trap: CardInstance = _create_card_instance({
        "id": 3007,
        "name": "Dust Tornado",
        "card_type": "trap",
        "race": "Normal",
    }, DuelManager.OWNER_PLAYER, DuelManager.CARD_ZONE_SPELL_TRAP, 1)
    player_trap.face_up = false
    player_trap.was_set_this_turn = true

    var player_spell_slots: Array = duel_manager.player_state[DuelManager.ZONE_KEY_SPELL_TRAP] as Array
    player_spell_slots[1] = player_trap

    duel_manager.current_phase = DuelManager.PHASE_END
    duel_manager._on_next_phase_button_pressed()

    assert(not player_trap.was_set_this_turn, "Turn handoff must clear was_set_this_turn for the player ending their turn.")
    assert(not duel_manager.is_player_turn, "Turn should pass to enemy after end phase.")

func test_counter_trap_negates_previous_chain_link_effect() -> void:
    var duel_manager: DuelManager = _build_test_duel_manager()

    var player_spell: CardInstance = _create_card_instance({
        "id": 3008,
        "name": "Ookazi",
        "card_type": "spell",
        "race": "Normal",
    }, DuelManager.OWNER_PLAYER, DuelManager.CARD_ZONE_HAND)
    var enemy_counter_trap: CardInstance = _create_card_instance({
        "id": 3009,
        "name": "Magic Jammer",
        "card_type": "trap",
        "race": "Counter",
    }, DuelManager.OWNER_ENEMY, DuelManager.CARD_ZONE_SPELL_TRAP, 0)
    enemy_counter_trap.face_up = false
    enemy_counter_trap.was_set_this_turn = false

    var player_hand: Array = duel_manager.player_state[DuelManager.ZONE_KEY_HAND] as Array
    player_hand.append(player_spell)

    var enemy_spell_slots: Array = duel_manager.enemy_state[DuelManager.ZONE_KEY_SPELL_TRAP] as Array
    enemy_spell_slots[0] = enemy_counter_trap

    var success: bool = duel_manager.action_resolver.execute_action(RuleEngine.ACTION_ACTIVATE_SPELL, null, player_spell, duel_manager)

    assert(success, "Spell activation should succeed even if later negated in chain.")
    assert(player_spell.current_zone == DuelManager.CARD_ZONE_GRAVEYARD, "Activated spell should go to graveyard after chain resolution.")
    assert(enemy_counter_trap.current_zone == DuelManager.CARD_ZONE_GRAVEYARD, "Counter trap should go to graveyard after resolving.")
    assert(duel_manager.get_life_points(DuelManager.OWNER_ENEMY) == 8000, "Negated Ookazi must not deal burn damage.")

func _build_test_duel_manager() -> DuelManager:
    var duel_manager: DuelManager = DuelManager.new()
    duel_manager.phase_manager = PhaseManager.new()
    duel_manager.turn_manager = TurnManager.new()
    duel_manager.turn_manager.start_duel(TurnManager.OWNER_PLAYER)

    duel_manager.player_state = duel_manager._create_duelist_state(DuelManager.OWNER_PLAYER)
    duel_manager.enemy_state = duel_manager._create_duelist_state(DuelManager.OWNER_ENEMY)

    var player_deck: Array = duel_manager.player_state[DuelManager.ZONE_KEY_DECK] as Array
    var enemy_deck: Array = duel_manager.enemy_state[DuelManager.ZONE_KEY_DECK] as Array
    player_deck.append(_create_card_instance({"id": 3901, "name": "Deck Filler P", "card_type": "monster", "atk": 1000, "def": 1000}, DuelManager.OWNER_PLAYER, DuelManager.CARD_ZONE_DECK))
    enemy_deck.append(_create_card_instance({"id": 3902, "name": "Deck Filler E", "card_type": "monster", "atk": 1000, "def": 1000}, DuelManager.OWNER_ENEMY, DuelManager.CARD_ZONE_DECK))

    duel_manager.current_phase = DuelManager.PHASE_MAIN_1
    duel_manager.is_player_turn = true
    duel_manager.chain_in_progress = false
    duel_manager.chain_response_window_owner = DuelManager.OWNER_PLAYER
    duel_manager.chain_min_response_speed = 1
    duel_manager.chain_links.clear()
    return duel_manager

func _create_card_instance(card_data: Dictionary, owner_id: int, zone_id: int, slot_index: int = -1) -> CardInstance:
    var card_instance: CardInstance = CardInstance.new()
    card_instance.setup(card_data, owner_id, zone_id, slot_index)
    return card_instance
