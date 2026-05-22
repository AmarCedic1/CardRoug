extends Node
class_name TestCoreRuleEngine

func test_deck_out_on_required_draw_ends_duel() -> void:
    var duel_manager: DuelManager = _build_test_duel_manager()
    duel_manager.is_player_turn = true

    var player_deck: Array = duel_manager.player_state[DuelManager.ZONE_KEY_DECK] as Array
    player_deck.clear()

    duel_manager._start_turn_draw_step()

    assert(duel_manager.duel_has_ended, "Duel should end when active player cannot draw.")
    assert(duel_manager.winner_owner == DuelManager.OWNER_ENEMY, "Opponent should win when player decks out.")
    assert(duel_manager.duel_end_reason == DuelManager.RESULT_REASON_DECK_OUT, "Deck-out reason should be recorded.")

func test_life_point_zero_ends_duel_for_opponent() -> void:
    var duel_manager: DuelManager = _build_test_duel_manager()

    duel_manager._apply_life_point_damage(DuelManager.OWNER_ENEMY, DuelManager.START_LIFE_POINTS)

    assert(duel_manager.duel_has_ended, "Duel should end when enemy LP reach zero.")
    assert(duel_manager.winner_owner == DuelManager.OWNER_PLAYER, "Player should win when enemy LP hit zero.")
    assert(duel_manager.duel_end_reason == DuelManager.RESULT_REASON_LIFE_POINTS, "Life point reason should be recorded.")

func test_simultaneous_zero_life_points_results_in_draw() -> void:
    var duel_manager: DuelManager = _build_test_duel_manager()

    duel_manager.player_state[DuelManager.STATE_KEY_LIFE_POINTS] = 0
    duel_manager.enemy_state[DuelManager.STATE_KEY_LIFE_POINTS] = 0
    duel_manager._run_state_based_checks()

    assert(duel_manager.duel_has_ended, "Duel should end when both players reach zero LP.")
    assert(duel_manager.winner_owner == DuelManager.OWNER_DRAW, "Result should be draw for simultaneous LP zero.")
    assert(duel_manager.duel_end_reason == DuelManager.RESULT_REASON_DRAW, "Draw reason should be recorded.")

func test_surrender_ends_duel_immediately() -> void:
    var duel_manager: DuelManager = _build_test_duel_manager()

    duel_manager.surrender(DuelManager.OWNER_PLAYER)

    assert(duel_manager.duel_has_ended, "Duel should end on surrender.")
    assert(duel_manager.winner_owner == DuelManager.OWNER_ENEMY, "Opponent should win when player surrenders.")
    assert(duel_manager.duel_end_reason == DuelManager.RESULT_REASON_SURRENDER, "Surrender reason should be recorded.")

func test_illegal_card_type_in_monster_zone_is_sent_to_grave() -> void:
    var duel_manager: DuelManager = _build_test_duel_manager()

    var illegal_spell: CardInstance = _create_card_instance("spell", DuelManager.OWNER_PLAYER, DuelManager.CARD_ZONE_MONSTER, 0)
    var monster_slots: Array = duel_manager.player_state[DuelManager.ZONE_KEY_MONSTER] as Array
    monster_slots[0] = illegal_spell

    duel_manager._run_state_based_checks()

    var player_graveyard: Array = duel_manager.player_state[DuelManager.ZONE_KEY_GRAVEYARD] as Array
    assert(monster_slots[0] == null, "Illegal spell card should be removed from monster slot.")
    assert(player_graveyard.has(illegal_spell), "Illegal spell card should be sent to graveyard.")

func test_invalid_move_does_not_remove_card_from_origin_zone() -> void:
    var duel_manager: DuelManager = _build_test_duel_manager()

    var hand_card: CardInstance = _create_card_instance("monster", DuelManager.OWNER_PLAYER, DuelManager.CARD_ZONE_HAND)
    var blocker_card: CardInstance = _create_card_instance("monster", DuelManager.OWNER_PLAYER, DuelManager.CARD_ZONE_MONSTER, 0)

    var player_hand: Array = duel_manager.player_state[DuelManager.ZONE_KEY_HAND] as Array
    var monster_slots: Array = duel_manager.player_state[DuelManager.ZONE_KEY_MONSTER] as Array
    player_hand.append(hand_card)
    monster_slots[0] = blocker_card

    var moved: bool = duel_manager.move_card_to_zone(null, hand_card, DuelManager.CARD_ZONE_MONSTER, 0)

    assert(not moved, "Move should fail when target monster slot is occupied.")
    assert(player_hand.has(hand_card), "Failed move must not remove card from origin zone.")
    assert(hand_card.current_zone == DuelManager.CARD_ZONE_HAND, "Card zone should remain unchanged after failed move.")

func _build_test_duel_manager() -> DuelManager:
    var duel_manager: DuelManager = DuelManager.new()
    duel_manager.phase_manager = PhaseManager.new()
    duel_manager.turn_manager = TurnManager.new()
    duel_manager.player_state = duel_manager._create_duelist_state(DuelManager.OWNER_PLAYER)
    duel_manager.enemy_state = duel_manager._create_duelist_state(DuelManager.OWNER_ENEMY)
    duel_manager.current_phase = DuelManager.PHASE_MAIN_1
    duel_manager.is_player_turn = true
    return duel_manager

func _create_card_instance(card_type: String, owner_id: int, zone_id: int, slot_index: int = -1) -> CardInstance:
    var card_instance: CardInstance = CardInstance.new()
    var card_data: Dictionary = {
        "id": 9000,
        "name": "CoreRuleTestCard",
        "card_type": card_type,
        "atk": 1000,
        "def": 1000,
    }
    card_instance.setup(card_data, owner_id, zone_id, slot_index)
    return card_instance
