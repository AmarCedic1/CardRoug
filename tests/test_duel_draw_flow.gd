extends Node
class_name TestDuelDrawFlow

func test_duel_start_draws_opening_hands_and_turn_one_draw() -> void:
    var duel_manager: DuelManager = _build_initialized_duel_manager()

    var player_hand: Array = duel_manager.player_state[DuelManager.ZONE_KEY_HAND] as Array
    var enemy_hand: Array = duel_manager.enemy_state[DuelManager.ZONE_KEY_HAND] as Array

    assert(player_hand.size() == 6, "Player should have opening hand plus turn 1 draw.")
    assert(enemy_hand.size() == 5, "Enemy should have opening hand after duel start.")
    assert(duel_manager.current_phase == DuelManager.PHASE_DRAW, "Duel should start at Draw Phase before Standby/Main progression.")

func test_phase_progression_includes_standby_before_main_1() -> void:
    var duel_manager: DuelManager = _build_initialized_duel_manager()

    duel_manager._on_next_phase_button_pressed()
    assert(duel_manager.current_phase == DuelManager.PHASE_STANDBY, "After Draw, duel should advance to Standby.")

    duel_manager._on_next_phase_button_pressed()
    assert(duel_manager.current_phase == DuelManager.PHASE_MAIN_1, "After Standby, duel should advance to Main 1.")

func test_next_turn_draw_step_draws_for_new_turn_player() -> void:
    var duel_manager: DuelManager = _build_initialized_duel_manager()

    duel_manager.set_current_phase(DuelManager.PHASE_END)
    duel_manager._on_next_phase_button_pressed()

    var enemy_hand: Array = duel_manager.enemy_state[DuelManager.ZONE_KEY_HAND] as Array
    assert(not duel_manager.is_player_turn, "Turn should pass to enemy after ending player turn.")
    assert(enemy_hand.size() == 6, "New turn player should draw at start of turn.")
    assert(duel_manager.current_phase == DuelManager.PHASE_DRAW, "A new turn should begin in Draw Phase.")

func _build_initialized_duel_manager() -> DuelManager:
    var duel_manager: DuelManager = DuelManager.new()
    duel_manager.phase_manager = PhaseManager.new()
    duel_manager.turn_manager = TurnManager.new()

    var card_database: GoatCarddatabase = GoatCarddatabase.new()
    card_database.load_goat_cards()
    duel_manager.card_database = card_database

    var hand_zone: Control = Control.new()
    duel_manager.zones["PlayerHand"] = hand_zone

    duel_manager._initialize_duel_state()
    return duel_manager
