extends Node
class_name TestDuelLifecycle

var _activate_events: int = 0
var _resolve_events: int = 0
var _grave_events: int = 0
var _destroy_events: int = 0
var _banish_events: int = 0

func test_activate_normal_spell_moves_to_graveyard() -> void:
    _reset_event_counters()
    var duel_manager: DuelManager = _build_test_duel_manager()
    duel_manager.on_activate.connect(_on_activate)
    duel_manager.on_resolve.connect(_on_resolve)
    duel_manager.on_send_to_grave.connect(_on_send_to_grave)

    var card_instance: CardInstance = _create_card_instance("spell", DuelManager.OWNER_PLAYER, DuelManager.CARD_ZONE_HAND)
    var player_hand: Array = duel_manager.player_state[DuelManager.ZONE_KEY_HAND] as Array
    player_hand.append(card_instance)

    var success: bool = duel_manager.action_resolver.execute_action(RuleEngine.ACTION_ACTIVATE_SPELL, null, card_instance, duel_manager)

    assert(success, "Normal spell activation should resolve successfully.")
    assert(card_instance.current_zone == DuelManager.CARD_ZONE_GRAVEYARD, "Resolved normal spell must be in graveyard.")

    var player_graveyard: Array = duel_manager.player_state[DuelManager.ZONE_KEY_GRAVEYARD] as Array
    assert(player_graveyard.has(card_instance), "Graveyard should contain the resolved spell.")
    assert(_activate_events == 1, "Activation event should be emitted exactly once.")
    assert(_resolve_events == 1, "Resolve event should be emitted exactly once.")
    assert(_grave_events == 1, "Send-to-grave event should be emitted exactly once.")

func test_destroy_monster_moves_to_graveyard() -> void:
    _reset_event_counters()
    var duel_manager: DuelManager = _build_test_duel_manager()
    duel_manager.on_destroy.connect(_on_destroy)
    duel_manager.on_send_to_grave.connect(_on_send_to_grave)

    var card_instance: CardInstance = _create_card_instance("monster", DuelManager.OWNER_PLAYER, DuelManager.CARD_ZONE_MONSTER, 2)
    var monster_slots: Array = duel_manager.player_state[DuelManager.ZONE_KEY_MONSTER] as Array
    monster_slots[2] = card_instance

    var success: bool = duel_manager.action_resolver.destroy_card(null, card_instance, duel_manager, &"battle")

    assert(success, "Destroy flow should succeed.")
    assert(card_instance.current_zone == DuelManager.CARD_ZONE_GRAVEYARD, "Destroyed monster must be moved to graveyard.")
    assert(monster_slots[2] == null, "Original monster slot should be emptied.")

    var player_graveyard: Array = duel_manager.player_state[DuelManager.ZONE_KEY_GRAVEYARD] as Array
    assert(player_graveyard.has(card_instance), "Graveyard should contain destroyed monster.")
    assert(_destroy_events == 1, "Destroy event should be emitted once.")
    assert(_grave_events == 1, "Send-to-grave should be emitted once for destroy flow.")

func test_banish_flow_moves_card_to_banished_zone() -> void:
    _reset_event_counters()
    var duel_manager: DuelManager = _build_test_duel_manager()
    duel_manager.on_banish.connect(_on_banish)

    var card_instance: CardInstance = _create_card_instance("monster", DuelManager.OWNER_PLAYER, DuelManager.CARD_ZONE_MONSTER, 1)
    var monster_slots: Array = duel_manager.player_state[DuelManager.ZONE_KEY_MONSTER] as Array
    monster_slots[1] = card_instance

    var success: bool = duel_manager.action_resolver.banish_card(null, card_instance, duel_manager, &"effect")

    assert(success, "Banish flow should succeed.")
    assert(card_instance.current_zone == DuelManager.CARD_ZONE_BANISHED, "Banished card must be in banished zone.")
    assert(monster_slots[1] == null, "Original monster slot should be emptied after banish.")

    var player_banished: Array = duel_manager.player_state[DuelManager.ZONE_KEY_BANISHED] as Array
    assert(player_banished.has(card_instance), "Banished zone should contain banished card.")
    assert(_banish_events == 1, "Banish event should be emitted once.")

func _build_test_duel_manager() -> DuelManager:
    var duel_manager: DuelManager = DuelManager.new()
    duel_manager.player_state = duel_manager._create_duelist_state(DuelManager.OWNER_PLAYER)
    duel_manager.enemy_state = duel_manager._create_duelist_state(DuelManager.OWNER_ENEMY)
    duel_manager.current_phase = DuelManager.PHASE_MAIN_1
    duel_manager.is_player_turn = true
    return duel_manager

func _create_card_instance(card_type: String, owner_id: int, zone_id: int, slot_index: int = -1) -> CardInstance:
    var card_instance: CardInstance = CardInstance.new()
    var card_data: Dictionary = {
        "id": 1000,
        "name": "TestCard",
        "card_type": card_type,
    }
    card_instance.setup(card_data, owner_id, zone_id, slot_index)
    return card_instance

func _reset_event_counters() -> void:
    _activate_events = 0
    _resolve_events = 0
    _grave_events = 0
    _destroy_events = 0
    _banish_events = 0

func _on_activate(card_instance: RefCounted, action: StringName) -> void:
    _activate_events += 1

func _on_resolve(card_instance: RefCounted, action: StringName, success: bool) -> void:
    _resolve_events += 1

func _on_send_to_grave(card_instance: RefCounted, reason: StringName) -> void:
    _grave_events += 1

func _on_destroy(card_instance: RefCounted, reason: StringName) -> void:
    _destroy_events += 1

func _on_banish(card_instance: RefCounted, reason: StringName) -> void:
    _banish_events += 1
