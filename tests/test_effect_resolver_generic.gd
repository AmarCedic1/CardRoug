extends Node
class_name TestEffectResolverGeneric

func test_generic_draw_effect_text_draws_cards() -> void:
    var duel_manager: DuelManager = _build_test_duel_manager()

    var draw_spell: CardInstance = _create_card_instance({
        "id": 4101,
        "name": "Test Generic Draw",
        "card_type": "spell",
        "race": "Normal",
        "effect_text": "Draw 2 cards.",
    }, DuelManager.OWNER_PLAYER, DuelManager.CARD_ZONE_HAND)

    var player_hand: Array = duel_manager.player_state[DuelManager.ZONE_KEY_HAND] as Array
    player_hand.append(draw_spell)

    var success: bool = duel_manager.action_resolver.execute_action(RuleEngine.ACTION_ACTIVATE_SPELL, null, draw_spell, duel_manager)

    assert(success, "Generic draw spell activation should resolve successfully.")
    assert(draw_spell.current_zone == DuelManager.CARD_ZONE_GRAVEYARD, "Resolved draw spell should be sent to graveyard.")
    assert(player_hand.size() == 2, "After activating a draw-2 spell from hand, player should have 2 cards in hand.")

func test_generic_burn_effect_text_damages_opponent() -> void:
    var duel_manager: DuelManager = _build_test_duel_manager()

    var burn_spell: CardInstance = _create_card_instance({
        "id": 4102,
        "name": "Test Generic Burn",
        "card_type": "spell",
        "race": "Normal",
        "effect_text": "Inflict 700 points of damage to your opponent.",
    }, DuelManager.OWNER_PLAYER, DuelManager.CARD_ZONE_HAND)

    var player_hand: Array = duel_manager.player_state[DuelManager.ZONE_KEY_HAND] as Array
    player_hand.append(burn_spell)

    var success: bool = duel_manager.action_resolver.execute_action(RuleEngine.ACTION_ACTIVATE_SPELL, null, burn_spell, duel_manager)

    assert(success, "Generic burn spell activation should resolve successfully.")
    assert(duel_manager.get_life_points(DuelManager.OWNER_ENEMY) == 7300, "Opponent should lose LP based on parsed burn amount.")

func test_generic_destroy_monster_effect_text_uses_opponent_target() -> void:
    var duel_manager: DuelManager = _build_test_duel_manager()

    var enemy_monster: CardInstance = _create_card_instance({
        "id": 4103,
        "name": "Enemy Target",
        "card_type": "monster",
        "atk": 1000,
        "def": 1000,
    }, DuelManager.OWNER_ENEMY, DuelManager.CARD_ZONE_MONSTER, 0)

    var enemy_monster_slots: Array = duel_manager.enemy_state[DuelManager.ZONE_KEY_MONSTER] as Array
    enemy_monster_slots[0] = enemy_monster

    var destroy_spell: CardInstance = _create_card_instance({
        "id": 4104,
        "name": "Test Generic Destroy",
        "card_type": "spell",
        "race": "Normal",
        "effect_text": "Destroy 1 monster your opponent controls.",
    }, DuelManager.OWNER_PLAYER, DuelManager.CARD_ZONE_HAND)

    var player_hand: Array = duel_manager.player_state[DuelManager.ZONE_KEY_HAND] as Array
    player_hand.append(destroy_spell)

    var success: bool = duel_manager.action_resolver.execute_action(RuleEngine.ACTION_ACTIVATE_SPELL, null, destroy_spell, duel_manager)

    assert(success, "Generic destroy spell activation should resolve successfully.")
    assert(enemy_monster.current_zone == DuelManager.CARD_ZONE_GRAVEYARD, "Opponent monster should be destroyed by parsed destroy effect.")

func test_generic_destroy_all_opponent_spell_traps_effect_text_wipes_backrow() -> void:
    var duel_manager: DuelManager = _build_test_duel_manager()

    var enemy_spell_one: CardInstance = _create_card_instance({
        "id": 4105,
        "name": "Enemy Backrow One",
        "card_type": "spell",
        "race": "Normal",
    }, DuelManager.OWNER_ENEMY, DuelManager.CARD_ZONE_SPELL_TRAP, 0)
    var enemy_spell_two: CardInstance = _create_card_instance({
        "id": 4106,
        "name": "Enemy Backrow Two",
        "card_type": "trap",
        "race": "Normal",
    }, DuelManager.OWNER_ENEMY, DuelManager.CARD_ZONE_SPELL_TRAP, 1)

    var enemy_spell_slots: Array = duel_manager.enemy_state[DuelManager.ZONE_KEY_SPELL_TRAP] as Array
    enemy_spell_slots[0] = enemy_spell_one
    enemy_spell_slots[1] = enemy_spell_two

    var wipe_spell: CardInstance = _create_card_instance({
        "id": 4107,
        "name": "Test Generic Backrow Wipe",
        "card_type": "spell",
        "race": "Normal",
        "effect_text": "Destroy all Spell and Trap Cards your opponent controls.",
    }, DuelManager.OWNER_PLAYER, DuelManager.CARD_ZONE_HAND)

    var player_hand: Array = duel_manager.player_state[DuelManager.ZONE_KEY_HAND] as Array
    player_hand.append(wipe_spell)

    var success: bool = duel_manager.action_resolver.execute_action(RuleEngine.ACTION_ACTIVATE_SPELL, null, wipe_spell, duel_manager)

    assert(success, "Generic backrow wipe spell should resolve successfully.")
    assert(enemy_spell_one.current_zone == DuelManager.CARD_ZONE_GRAVEYARD, "First opponent backrow card should be destroyed by parsed wipe effect.")
    assert(enemy_spell_two.current_zone == DuelManager.CARD_ZONE_GRAVEYARD, "Second opponent backrow card should be destroyed by parsed wipe effect.")

func test_generic_banish_opponent_monster_effect_text_banishes_target() -> void:
    var duel_manager: DuelManager = _build_test_duel_manager()

    var enemy_monster: CardInstance = _create_card_instance({
        "id": 4108,
        "name": "Enemy Banish Target",
        "card_type": "monster",
        "atk": 1000,
        "def": 1000,
    }, DuelManager.OWNER_ENEMY, DuelManager.CARD_ZONE_MONSTER, 0)

    var enemy_monster_slots: Array = duel_manager.enemy_state[DuelManager.ZONE_KEY_MONSTER] as Array
    enemy_monster_slots[0] = enemy_monster

    var banish_spell: CardInstance = _create_card_instance({
        "id": 4109,
        "name": "Test Generic Banish",
        "card_type": "spell",
        "race": "Normal",
        "effect_text": "Remove from play 1 monster on your opponent's side of the field.",
    }, DuelManager.OWNER_PLAYER, DuelManager.CARD_ZONE_HAND)

    var player_hand: Array = duel_manager.player_state[DuelManager.ZONE_KEY_HAND] as Array
    player_hand.append(banish_spell)

    var success: bool = duel_manager.action_resolver.execute_action(RuleEngine.ACTION_ACTIVATE_SPELL, null, banish_spell, duel_manager)

    assert(success, "Generic banish spell activation should resolve successfully.")
    assert(enemy_monster.current_zone == DuelManager.CARD_ZONE_BANISHED, "Opponent monster should be banished by parsed effect.")

func test_generic_return_opponent_monster_to_hand_effect_text_bounces_target() -> void:
    var duel_manager: DuelManager = _build_test_duel_manager()

    var enemy_monster: CardInstance = _create_card_instance({
        "id": 4110,
        "name": "Enemy Bounce Target",
        "card_type": "monster",
        "atk": 1000,
        "def": 1000,
    }, DuelManager.OWNER_ENEMY, DuelManager.CARD_ZONE_MONSTER, 0)

    var enemy_monster_slots: Array = duel_manager.enemy_state[DuelManager.ZONE_KEY_MONSTER] as Array
    enemy_monster_slots[0] = enemy_monster

    var bounce_spell: CardInstance = _create_card_instance({
        "id": 4111,
        "name": "Test Generic Bounce",
        "card_type": "spell",
        "race": "Normal",
        "effect_text": "Return 1 monster on your opponent's side of the field to the owner's hand.",
    }, DuelManager.OWNER_PLAYER, DuelManager.CARD_ZONE_HAND)

    var player_hand: Array = duel_manager.player_state[DuelManager.ZONE_KEY_HAND] as Array
    player_hand.append(bounce_spell)

    var success: bool = duel_manager.action_resolver.execute_action(RuleEngine.ACTION_ACTIVATE_SPELL, null, bounce_spell, duel_manager)

    var enemy_hand: Array = duel_manager.enemy_state[DuelManager.ZONE_KEY_HAND] as Array
    assert(success, "Generic bounce spell activation should resolve successfully.")
    assert(enemy_monster.current_zone == DuelManager.CARD_ZONE_HAND, "Opponent monster should be returned to hand by parsed bounce effect.")
    assert(enemy_hand.has(enemy_monster), "Returned opponent monster should appear in opponent hand zone array.")

func test_generic_return_all_monsters_to_hand_effect_text_bounces_board() -> void:
    var duel_manager: DuelManager = _build_test_duel_manager()

    var player_monster: CardInstance = _create_card_instance({
        "id": 4112,
        "name": "Player Bounce Target",
        "card_type": "monster",
        "atk": 1000,
        "def": 1000,
    }, DuelManager.OWNER_PLAYER, DuelManager.CARD_ZONE_MONSTER, 0)
    var enemy_monster: CardInstance = _create_card_instance({
        "id": 4113,
        "name": "Enemy Bounce Target",
        "card_type": "monster",
        "atk": 1000,
        "def": 1000,
    }, DuelManager.OWNER_ENEMY, DuelManager.CARD_ZONE_MONSTER, 0)

    var player_monster_slots: Array = duel_manager.player_state[DuelManager.ZONE_KEY_MONSTER] as Array
    var enemy_monster_slots: Array = duel_manager.enemy_state[DuelManager.ZONE_KEY_MONSTER] as Array
    player_monster_slots[0] = player_monster
    enemy_monster_slots[0] = enemy_monster

    var mass_bounce_spell: CardInstance = _create_card_instance({
        "id": 4114,
        "name": "Test Generic Mass Bounce",
        "card_type": "spell",
        "race": "Normal",
        "effect_text": "Return all Monster Cards on the field to their respective hands.",
    }, DuelManager.OWNER_PLAYER, DuelManager.CARD_ZONE_HAND)

    var player_hand: Array = duel_manager.player_state[DuelManager.ZONE_KEY_HAND] as Array
    player_hand.append(mass_bounce_spell)

    var success: bool = duel_manager.action_resolver.execute_action(RuleEngine.ACTION_ACTIVATE_SPELL, null, mass_bounce_spell, duel_manager)

    var final_player_hand: Array = duel_manager.player_state[DuelManager.ZONE_KEY_HAND] as Array
    var final_enemy_hand: Array = duel_manager.enemy_state[DuelManager.ZONE_KEY_HAND] as Array
    assert(success, "Generic mass bounce spell activation should resolve successfully.")
    assert(player_monster.current_zone == DuelManager.CARD_ZONE_HAND, "Player monster should return to hand from parsed mass bounce effect.")
    assert(enemy_monster.current_zone == DuelManager.CARD_ZONE_HAND, "Enemy monster should return to hand from parsed mass bounce effect.")
    assert(final_player_hand.has(player_monster), "Player hand should contain bounced player monster.")
    assert(final_enemy_hand.has(enemy_monster), "Enemy hand should contain bounced enemy monster.")

func test_cancel_effect_target_selection_rolls_back_activation_state() -> void:
    var duel_manager: DuelManager = _build_test_duel_manager()

    var enemy_monster: CardInstance = _create_card_instance({
        "id": 4115,
        "name": "Enemy Cancel Target",
        "card_type": "monster",
        "atk": 1200,
        "def": 1200,
    }, DuelManager.OWNER_ENEMY, DuelManager.CARD_ZONE_MONSTER, 0)

    var enemy_monster_slots: Array = duel_manager.enemy_state[DuelManager.ZONE_KEY_MONSTER] as Array
    enemy_monster_slots[0] = enemy_monster

    var target_spell: CardInstance = _create_card_instance({
        "id": 4116,
        "name": "Target Cancel Test",
        "card_type": "spell",
        "race": "Normal",
        "effect_text": "Destroy 1 monster your opponent controls.",
    }, DuelManager.OWNER_PLAYER, DuelManager.CARD_ZONE_HAND)

    var player_hand: Array = duel_manager.player_state[DuelManager.ZONE_KEY_HAND] as Array
    player_hand.append(target_spell)

    var rollback_context: Dictionary = duel_manager._capture_effect_activation_rollback_context(target_spell, DuelManager.ACTION_ACTIVATE_SPELL)
    var prepared: bool = duel_manager._prepare_card_for_spell_trap_activation(DuelManager.ACTION_ACTIVATE_SPELL, null, target_spell)
    assert(prepared, "Spell should prepare for activation before target selection.")

    target_spell.mark_activated_this_turn()

    var chain_link: Dictionary = duel_manager._make_chain_link(target_spell, DuelManager.ACTION_ACTIVATE_SPELL, 1)
    var selectable_targets: Array[CardInstance] = [enemy_monster]
    var began_selection: bool = duel_manager._begin_effect_target_selection(chain_link, selectable_targets, rollback_context)
    assert(began_selection, "Effect target selection should begin when valid targets exist.")
    assert(target_spell.current_zone == DuelManager.CARD_ZONE_SPELL_TRAP, "Prepared spell should be in spell/trap zone before cancel.")

    duel_manager._on_target_selection_cancel_pressed()

    var final_player_hand: Array = duel_manager.player_state[DuelManager.ZONE_KEY_HAND] as Array
    assert(target_spell.current_zone == DuelManager.CARD_ZONE_HAND, "Canceling target selection should return spell to hand.")
    assert(final_player_hand.has(target_spell), "Canceled activation card should be present in player hand.")
    assert(not target_spell.has_activated_this_turn, "Canceling target selection should restore activation flag state.")
    assert(not duel_manager.target_selection_active, "Target selection mode should be cleared after cancel.")

func _build_test_duel_manager() -> DuelManager:
    var duel_manager: DuelManager = DuelManager.new()
    duel_manager.phase_manager = PhaseManager.new()
    duel_manager.turn_manager = TurnManager.new()
    duel_manager.turn_manager.start_duel(TurnManager.OWNER_PLAYER)

    duel_manager.player_state = duel_manager._create_duelist_state(DuelManager.OWNER_PLAYER)
    duel_manager.enemy_state = duel_manager._create_duelist_state(DuelManager.OWNER_ENEMY)

    _append_deck_filler_for_owner(duel_manager, DuelManager.OWNER_PLAYER, 5)
    _append_deck_filler_for_owner(duel_manager, DuelManager.OWNER_ENEMY, 5)

    duel_manager.current_phase = DuelManager.PHASE_MAIN_1
    duel_manager.is_player_turn = true
    duel_manager.chain_in_progress = false
    duel_manager.chain_response_window_owner = DuelManager.OWNER_PLAYER
    duel_manager.chain_min_response_speed = 1
    duel_manager.chain_links.clear()
    return duel_manager

func _append_deck_filler_for_owner(duel_manager: DuelManager, owner_id: int, count: int) -> void:
    var target_state: Dictionary = duel_manager.player_state if owner_id == DuelManager.OWNER_PLAYER else duel_manager.enemy_state
    var deck_cards: Array = target_state[DuelManager.ZONE_KEY_DECK] as Array
    for card_index: int in range(count):
        var filler_card: CardInstance = _create_card_instance({
            "id": 5000 + card_index,
            "name": "Deck Filler %d" % card_index,
            "card_type": "monster",
            "atk": 1000,
            "def": 1000,
        }, owner_id, DuelManager.CARD_ZONE_DECK)
        deck_cards.append(filler_card)

func _create_card_instance(card_data: Dictionary, owner_id: int, zone_id: int, slot_index: int = -1) -> CardInstance:
    var card_instance: CardInstance = CardInstance.new()
    card_instance.setup(card_data, owner_id, zone_id, slot_index)
    return card_instance
