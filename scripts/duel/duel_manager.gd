extends Node
class_name DuelManager

const CARD_UI_SCENE: PackedScene = preload("res://ui/card_ui.tscn")
const CARD_INSTANCE_SCRIPT: Script = preload("res://scripts/cards/card_instance.gd")
const RULE_ENGINE_SCRIPT: Script = preload("res://scripts/duel/rule_engine.gd")
const ACTION_RESOLVER_SCRIPT: Script = preload("res://scripts/duel/action_resolver.gd")
const EFFECT_RESOLVER_SCRIPT: Script = preload("res://scripts/effects/effect_resolver.gd")

const OWNER_PLAYER: int = 0
const OWNER_ENEMY: int = 1
const OWNER_DRAW: int = -1

const RESULT_REASON_LIFE_POINTS: StringName = &"life_points"
const RESULT_REASON_DECK_OUT: StringName = &"deck_out"
const RESULT_REASON_SURRENDER: StringName = &"surrender"
const RESULT_REASON_DRAW: StringName = &"draw"

const CARD_ZONE_DECK: int = 0
const CARD_ZONE_HAND: int = 1
const CARD_ZONE_MONSTER: int = 2
const CARD_ZONE_SPELL_TRAP: int = 3
const CARD_ZONE_GRAVEYARD: int = 4
const CARD_ZONE_BANISHED: int = 5
const CARD_ZONE_EXTRA: int = 6

const BATTLE_POSITION_ATTACK: int = 0
const BATTLE_POSITION_DEFENSE: int = 1

const PLAYER_MONSTER_ZONE_PREFIX: String = "PlayerMonster"
const PLAYER_SPELL_ZONE_PREFIX: String = "PlayerSpell"
const ENEMY_MONSTER_ZONE_PREFIX: String = "EnemyMonster"
const ENEMY_SPELL_ZONE_PREFIX: String = "EnemySpell"
const PLAYER_MONSTER_ZONE_COUNT: int = 5
const PLAYER_SPELL_ZONE_COUNT: int = 5

const ACTION_NORMAL_SUMMON: StringName = RuleEngine.ACTION_NORMAL_SUMMON
const ACTION_SET_MONSTER: StringName = RuleEngine.ACTION_SET_MONSTER
const ACTION_ACTIVATE_SPELL: StringName = RuleEngine.ACTION_ACTIVATE_SPELL
const ACTION_ACTIVATE_SET_SPELL_TRAP: StringName = RuleEngine.ACTION_ACTIVATE_SET_SPELL_TRAP
const ACTION_SET_SPELL: StringName = RuleEngine.ACTION_SET_SPELL
const ACTION_POS_CHANGE: StringName = RuleEngine.ACTION_POS_CHANGE
const ACTION_FLIP_SUMMON: StringName = RuleEngine.ACTION_FLIP_SUMMON
const ACTION_DECLARE_ATTACK: StringName = RuleEngine.ACTION_DECLARE_ATTACK

const PHASE_DRAW: StringName = &"DRAW"
const PHASE_STANDBY: StringName = &"STANDBY"
const PHASE_MAIN_1: StringName = &"MAIN1"
const PHASE_BATTLE: StringName = &"BATTLE"
const PHASE_MAIN_2: StringName = &"MAIN2"
const PHASE_END: StringName = &"END"

const ZONE_KEY_DECK: StringName = &"deck"
const ZONE_KEY_HAND: StringName = &"hand"
const ZONE_KEY_MONSTER: StringName = &"monster"
const ZONE_KEY_SPELL_TRAP: StringName = &"spell_trap"
const ZONE_KEY_GRAVEYARD: StringName = &"graveyard"
const ZONE_KEY_BANISHED: StringName = &"banished"
const ZONE_KEY_EXTRA: StringName = &"extra"
const ZONE_KEY_FLAGS: StringName = &"flags"
const STATE_KEY_LIFE_POINTS: StringName = &"life_points"

const START_LIFE_POINTS: int = 8000
const DEFAULT_ZONE_CARD_SIZE: Vector2 = Vector2(120.0, 170.0)
const HAND_CARD_GAP: float = 30.0

var zones: Dictionary = {}
var player_zones: Dictionary = {}
var enemy_zones: Dictionary = {}

var player_state: Dictionary = {}
var enemy_state: Dictionary = {}
var card_instances_by_ui_id: Dictionary = {}

var phase_manager: PhaseManager = null
var turn_manager: TurnManager = null
var card_database: GoatCarddatabase = null
var next_phase_button: Button = null
var player_lp_label: Label = null
var enemy_lp_label: Label = null
var rule_engine: RuleEngine = RULE_ENGINE_SCRIPT.new() as RuleEngine
var action_resolver: ActionResolver = ACTION_RESOLVER_SCRIPT.new() as ActionResolver
var effect_resolver: EffectResolver = EFFECT_RESOLVER_SCRIPT.new() as EffectResolver

var current_phase: StringName = PHASE_DRAW
var is_player_turn: bool = true
var duel_has_ended: bool = false
var winner_owner: int = OWNER_DRAW
var duel_end_reason: StringName = StringName()
var enemy_turn_in_progress: bool = false
var chain_in_progress: bool = false
var chain_response_window_owner: int = OWNER_PLAYER
var chain_min_response_speed: int = 1
var chain_links: Array[Dictionary] = []
var chain_pass_count: int = 0

var chain_panel: PanelContainer = null
var chain_status_label: Label = null
var chain_response_label: Label = null
var chain_debug_label: Label = null
var chain_history_label: Label = null
var chain_pass_button: Button = null
var chain_enemy_pass_button: Button = null
var chain_stack_scroll: ScrollContainer = null
var chain_stack_vbox: VBoxContainer = null
var chain_vfx_overlay: ColorRect = null
var chain_history_lines: Array[String] = []
var last_rendered_chain_link_count: int = -1
var chain_stack_pulse_tween: Tween = null

var target_selection_panel: PanelContainer = null
var target_selection_label: Label = null
var target_selection_cancel_button: Button = null
var target_selection_active: bool = false
var target_selection_mode: StringName = StringName()
var target_selection_candidates: Array[CardInstance] = []
var pending_attack_attacker: CardInstance = null
var pending_attack_card_ui: CardUI = null
var pending_effect_link: Dictionary = {}
var pending_effect_rollback_context: Dictionary = {}

const TARGET_SELECTION_MODE_ATTACK: StringName = &"attack"
const TARGET_SELECTION_MODE_EFFECT: StringName = &"effect"
const CHAIN_HISTORY_MAX_LINES: int = 8

@export_group("Card Layout")
@export_range(-200.0, 200.0, 1.0) var global_card_size_offset_x: float = -10.0:
    set(value):
        global_card_size_offset_x = value
        _refresh_all_card_layouts()
@export_range(-200.0, 200.0, 1.0) var global_card_size_offset_y: float = -10.0:
    set(value):
        global_card_size_offset_y = value
        _refresh_all_card_layouts()

@export_group("Deck Setup")
@export var use_chain_test_decks: bool = true

@export_group("Enemy AI")
@export var enable_simple_enemy_ai: bool = true
@export_range(0.0, 1.0, 0.05) var enemy_ai_step_delay: float = 0.2

@export_group("Chain Debug")
@export var debug_manual_enemy_chain_responses: bool = false
@export_range(0.05, 0.6, 0.01) var chain_resolve_flash_duration: float = 0.14
@export_range(0.05, 0.8, 0.01) var chain_resolve_flash_alpha: float = 0.26

@export_group("Debug")
@export var debug_fill_all_zones_with_test_card: bool = false
@export var debug_test_cards_face_down: bool = false

signal phase_changed(phase: StringName, player_turn: bool)
signal on_send_to_grave(card_instance: RefCounted, reason: StringName)
signal on_banish(card_instance: RefCounted, reason: StringName)
signal on_destroy(card_instance: RefCounted, reason: StringName)
signal on_activate(card_instance: RefCounted, action: StringName)
signal on_resolve(card_instance: RefCounted, action: StringName, success: bool)
signal chain_state_changed(link_count: int, resolving: bool)
signal chain_response_window_changed(owner_id: int, is_open: bool, can_respond: bool)
signal duel_ended(winner: int, reason: StringName)

func _ready() -> void:
    await get_tree().process_frame

    phase_manager = get_node_or_null("../PhaseManager") as PhaseManager
    turn_manager = get_node_or_null("../TurnManager") as TurnManager
    card_database = get_node_or_null("../CardDatabase") as GoatCarddatabase
    next_phase_button = get_node_or_null("../NextPhaseButton") as Button
    player_lp_label = get_node_or_null("../PlayerLPLabel") as Label
    enemy_lp_label = get_node_or_null("../EnemyLPLabel") as Label

    if phase_manager == null:
        push_error("PhaseManager nicht gefunden.")
        return
    if turn_manager == null:
        push_error("TurnManager nicht gefunden.")
        return
    if card_database == null:
        push_error("CardDatabase nicht gefunden.")
        return

    _setup_chain_panel_ui()
    _setup_target_selection_ui()
    chain_state_changed.connect(_on_chain_state_changed_for_ui)
    on_activate.connect(_on_chain_activate_for_ui)
    on_resolve.connect(_on_chain_resolve_for_ui)

    if debug_fill_all_zones_with_test_card:
        _enter_debug_zone_preview_mode()
        return

    _initialize_duel_state()

func _initialize_duel_state() -> void:
    duel_has_ended = false
    winner_owner = OWNER_DRAW
    duel_end_reason = StringName()
    enemy_turn_in_progress = false
    chain_in_progress = false
    chain_response_window_owner = OWNER_PLAYER
    chain_min_response_speed = 1
    chain_links.clear()
    chain_pass_count = 0
    chain_history_lines.clear()
    _refresh_chain_panel_ui()

    player_state = _create_duelist_state(OWNER_PLAYER)
    enemy_state = _create_duelist_state(OWNER_ENEMY)

    _build_deck_for_state(player_state)
    _build_deck_for_state(enemy_state)

    _draw_cards(player_state, 5, true)
    _draw_cards(enemy_state, 5, false)
    _refresh_life_point_display()
    _run_state_based_checks()
    if duel_has_ended:
        return

    turn_manager.start_duel(TurnManager.OWNER_PLAYER)
    is_player_turn = turn_manager.is_player_turn()
    _start_turn_draw_step()

func _enter_debug_zone_preview_mode() -> void:
    if next_phase_button != null:
        next_phase_button.disabled = true
        next_phase_button.text = "Debug Zone Preview Mode"

    call_deferred("_spawn_debug_test_card_in_all_zones")

func _spawn_debug_test_card_in_all_zones() -> void:
    var card_template: Dictionary = _build_debug_test_card_data()
    var zone_names: Array[String] = []
    for zone_key: Variant in zones.keys():
        zone_names.append(str(zone_key))
    zone_names.sort()

    for zone_name: String in zone_names:
        var zone_node: Control = zones.get(zone_name) as Control
        if zone_node == null:
            continue

        _clear_existing_card_ui_children(zone_node)

        var card_ui: CardUI = CARD_UI_SCENE.instantiate() as CardUI
        card_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
        card_ui.set_card(card_template.duplicate(true) as Dictionary)
        card_ui.set_face_up(not debug_test_cards_face_down)
        zone_node.add_child(card_ui)
        _apply_card_layout_for_zone(card_ui, zone_node)

func _build_debug_test_card_data() -> Dictionary:
    var fallback_data: Dictionary = {
        "name": "Debug Card",
        "card_type": "monster",
        "atk": 2000,
        "def": 2000,
        "image_path": "",
    }

    if card_database == null:
        return fallback_data

    var all_ids: Array = card_database.cards.keys()
    if all_ids.is_empty():
        return fallback_data

    all_ids.sort()
    var first_id: int = int(all_ids[0])
    var candidate: Variant = card_database.get_card_by_id(first_id)
    if candidate is Dictionary:
        var candidate_dict: Dictionary = candidate as Dictionary
        return candidate_dict.duplicate(true) as Dictionary

    return fallback_data

func _clear_existing_card_ui_children(zone_node: Control) -> void:
    var children_to_remove: Array[CardUI] = []
    var child_count: int = zone_node.get_child_count()
    for child_index: int in range(child_count):
        var card_ui: CardUI = zone_node.get_child(child_index) as CardUI
        if card_ui == null:
            continue
        children_to_remove.append(card_ui)

    for card_ui: CardUI in children_to_remove:
        var ui_instance_id: int = card_ui.get_instance_id()
        if card_instances_by_ui_id.has(ui_instance_id):
            card_instances_by_ui_id.erase(ui_instance_id)
        card_ui.queue_free()

func _create_duelist_state(owner_id: int) -> Dictionary:
    var monster_slots: Array[Variant] = []
    var spell_slots: Array[Variant] = []

    for i: int in range(PLAYER_MONSTER_ZONE_COUNT):
        monster_slots.append(null)
    for j: int in range(PLAYER_SPELL_ZONE_COUNT):
        spell_slots.append(null)

    var state: Dictionary = {
        "owner": owner_id,
        ZONE_KEY_DECK: [],
        ZONE_KEY_HAND: [],
        ZONE_KEY_MONSTER: monster_slots,
        ZONE_KEY_SPELL_TRAP: spell_slots,
        ZONE_KEY_GRAVEYARD: [],
        ZONE_KEY_BANISHED: [],
        ZONE_KEY_EXTRA: [],
        STATE_KEY_LIFE_POINTS: START_LIFE_POINTS,
        ZONE_KEY_FLAGS: {
            "normal_summon_used": false,
        },
    }
    return state

func _build_deck_for_state(state: Dictionary) -> void:
    var deck_cards: Array = state[ZONE_KEY_DECK] as Array
    deck_cards.clear()

    var duel_owner: int = int(state.get("owner", OWNER_PLAYER))
    if use_chain_test_decks:
        var preferred_names: Array[String] = _get_chain_test_deck_for_owner(duel_owner)
        _append_named_cards_to_deck(deck_cards, duel_owner, preferred_names)
        _append_random_cards_to_deck(deck_cards, duel_owner, 40)
        return

    _append_random_cards_to_deck(deck_cards, duel_owner, 40)

func _get_chain_test_deck_for_owner(owner_id: int) -> Array[String]:
    var chain_test_names: Array[String] = [
        "Pot of Greed", "Pot of Greed",
        "Graceful Charity", "Graceful Charity",
        "Ookazi", "Ookazi",
        "Tremendous Fire", "Tremendous Fire",
        "Fissure", "Fissure",
        "Smashing Ground", "Smashing Ground",
        "Dark Hole", "Dark Hole",
        "Raigeki", "Raigeki",
        "Mystical Space Typhoon", "Mystical Space Typhoon",
        "Book of Moon", "Book of Moon",
        "Enemy Controller", "Enemy Controller",
        "Scapegoat", "Scapegoat",
        "Goblin Thief", "Goblin Thief",
        "Just Desserts", "Just Desserts",
        "Trap Hole", "Trap Hole",
        "Dust Tornado", "Dust Tornado",
        "Magic Jammer", "Magic Jammer",
        "Seven Tools of the Bandit", "Seven Tools of the Bandit",
        "Magic Drain", "Magic Drain",
        "Solemn Judgment", "Solemn Judgment",
    ]

    if owner_id == OWNER_ENEMY:
        chain_test_names.reverse()

    return chain_test_names

func _append_named_cards_to_deck(deck_cards: Array, duel_owner: int, card_names: Array[String]) -> void:
    for card_name: String in card_names:
        var card_data_variant: Variant = card_database.get_card_by_name(card_name)
        if not (card_data_variant is Dictionary):
            continue

        var card_data: Dictionary = card_data_variant as Dictionary
        var instance: CardInstance = CARD_INSTANCE_SCRIPT.new() as CardInstance
        instance.setup(card_data, duel_owner, CARD_ZONE_DECK)
        deck_cards.append(instance)

func _append_random_cards_to_deck(deck_cards: Array, duel_owner: int, target_count: int) -> void:
    var all_ids: Array = card_database.cards.keys()
    all_ids.shuffle()

    var max_cards: int = mini(maxi(0, target_count), all_ids.size())
    if deck_cards.size() >= max_cards:
        return

    for id_value: Variant in all_ids:
        if deck_cards.size() >= max_cards:
            break

        var card_id: int = int(id_value)
        var card_data_variant: Variant = card_database.get_card_by_id(card_id)
        if not (card_data_variant is Dictionary):
            continue

        var card_data: Dictionary = card_data_variant as Dictionary
        var instance: CardInstance = CARD_INSTANCE_SCRIPT.new() as CardInstance
        instance.setup(card_data, duel_owner, CARD_ZONE_DECK)
        deck_cards.append(instance)

func _draw_cards(state: Dictionary, amount: int, spawn_player_ui: bool) -> void:
    for i: int in range(amount):
        if duel_has_ended:
            return
        var drawn_card: RefCounted = _draw_one_card(state, spawn_player_ui)
        if drawn_card == null:
            return

func _draw_one_card(state: Dictionary, spawn_player_ui: bool) -> RefCounted:
    if duel_has_ended:
        return null

    var deck_cards: Array = state[ZONE_KEY_DECK] as Array
    if deck_cards.is_empty():
        var drawing_owner: int = int(state.get("owner", OWNER_PLAYER))
        var winner: int = OWNER_ENEMY if drawing_owner == OWNER_PLAYER else OWNER_PLAYER
        _end_duel(winner, RESULT_REASON_DECK_OUT)
        return null

    var drawn_card: RefCounted = deck_cards.pop_back() as RefCounted
    if drawn_card == null:
        var invalid_draw_owner: int = int(state.get("owner", OWNER_PLAYER))
        var invalid_draw_winner: int = OWNER_ENEMY if invalid_draw_owner == OWNER_PLAYER else OWNER_PLAYER
        _end_duel(invalid_draw_winner, RESULT_REASON_DECK_OUT)
        return null

    var hand_cards: Array = state[ZONE_KEY_HAND] as Array
    hand_cards.append(drawn_card)
    drawn_card.set_zone(CARD_ZONE_HAND)
    drawn_card.face_up = true

    if spawn_player_ui and int(state.get("owner", -1)) == OWNER_PLAYER:
        _spawn_player_hand_card_ui(drawn_card)

    return drawn_card

func _spawn_player_hand_card_ui(card_instance: RefCounted) -> void:
    var hand_zone: Control = zones.get("PlayerHand") as Control
    if hand_zone == null:
        push_warning("PlayerHand Zone fehlt.")
        return

    var card_ui: CardUI = CARD_UI_SCENE.instantiate() as CardUI
    card_ui.set_card(card_instance.card_data)
    hand_zone.add_child(card_ui)

    card_instances_by_ui_id[card_ui.get_instance_id()] = card_instance
    _sync_card_ui_from_instance(card_ui, card_instance)
    _layout_player_hand()

func _layout_player_hand() -> void:
    var hand_zone: Control = zones.get("PlayerHand") as Control
    if hand_zone == null:
        return

    var hand_card_size: Vector2 = _get_zone_card_size(hand_zone)
    var effective_hand_card_size: Vector2 = _get_effective_card_size(hand_card_size)
    var hand_card_scale: Vector2 = _get_zone_card_scale(hand_zone)
    var hand_offset: Vector2 = _get_zone_card_offset(hand_zone)
    var hand_spacing: float = effective_hand_card_size.x * hand_card_scale.x + HAND_CARD_GAP

    var child_count: int = hand_zone.get_child_count()
    for i: int in range(child_count):
        var card_node: CardUI = hand_zone.get_child(i) as CardUI
        if card_node == null:
            continue
        _apply_card_layout_for_zone(card_node, hand_zone)
        card_node.position = Vector2(20.0 + float(i) * hand_spacing, 0.0) + hand_offset

func _start_turn_draw_step() -> void:
    if duel_has_ended:
        return

    phase_manager.start_turn()
    set_current_phase(PHASE_DRAW)

    var active_state: Dictionary = _get_active_state()
    var should_spawn_ui: bool = is_player_turn
    _draw_one_card(active_state, should_spawn_ui)
    if duel_has_ended:
        return

    _reset_card_turn_flags_for_owner(_get_active_owner())
    turn_manager.reset_turn_flags()
    _run_state_based_checks()
    _try_start_enemy_turn()

func _finalize_turn_for_owner(owner_id: int) -> void:
    _reset_card_turn_flags_for_owner(owner_id)

func _get_active_owner() -> int:
    return OWNER_PLAYER if is_player_turn else OWNER_ENEMY

func _get_active_state() -> Dictionary:
    return player_state if is_player_turn else enemy_state

func _get_state_by_owner(owner_id: int) -> Dictionary:
    return player_state if owner_id == OWNER_PLAYER else enemy_state

func get_current_phase() -> StringName:
    return current_phase

func set_current_phase(phase: StringName) -> void:
    if duel_has_ended:
        return

    current_phase = phase
    phase_manager.current_phase = phase
    emit_signal("phase_changed", phase, is_player_turn)
    _refresh_phase_display()

func on_next_phase_button_pressed() -> void:
    _on_next_phase_button_pressed()

func _on_next_phase_button_pressed() -> void:
    if duel_has_ended:
        return
    if not is_player_turn and enable_simple_enemy_ai:
        return

    if current_phase == PHASE_END:
        _finalize_turn_for_owner(_get_active_owner())
        turn_manager.next_turn()
        is_player_turn = turn_manager.is_player_turn()
        _start_turn_draw_step()
        return

    var next_phase: StringName = phase_manager.next_phase()
    set_current_phase(next_phase)
    _run_state_based_checks()

func _refresh_phase_display() -> void:
    if next_phase_button == null:
        return

    if duel_has_ended:
        next_phase_button.disabled = true
        if winner_owner == OWNER_DRAW:
            next_phase_button.text = "Duel Ended | Draw"
        elif winner_owner == OWNER_PLAYER:
            next_phase_button.text = "Duel Ended | You Win"
        else:
            next_phase_button.text = "Duel Ended | Enemy Wins"
        return

    next_phase_button.disabled = (not is_player_turn and enable_simple_enemy_ai) or enemy_turn_in_progress
    var turn_text: String = "Your Turn" if is_player_turn else "Enemy Turn"
    var phase_text: String = _phase_to_text(current_phase)
    var advance_text: String = "End Turn" if current_phase == PHASE_END else "Next Phase"
    if enemy_turn_in_progress:
        advance_text = "Enemy Thinking"
    next_phase_button.text = "%s | %s | %s" % [turn_text, phase_text, advance_text]

func _phase_to_text(phase: StringName) -> String:
    if phase == PHASE_DRAW:
        return "Draw"
    if phase == PHASE_STANDBY:
        return "Standby"
    if phase == PHASE_MAIN_1:
        return "Main 1"
    if phase == PHASE_BATTLE:
        return "Battle"
    if phase == PHASE_MAIN_2:
        return "Main 2"
    if phase == PHASE_END:
        return "End"
    return str(phase)

func register_zone(zone_name: String, zone_node: Node, is_player: bool) -> void:
    zones[zone_name] = zone_node
    if is_player:
        player_zones[zone_name] = zone_node
    else:
        enemy_zones[zone_name] = zone_node

func on_card_clicked(card_ui: CardUI) -> void:
    if duel_has_ended:
        return

    var card_instance: RefCounted = _get_card_instance(card_ui)
    if card_instance == null:
        return

    var typed_card_instance: CardInstance = card_instance as CardInstance
    if typed_card_instance == null:
        return

    if _handle_target_selection_click(typed_card_instance):
        return

    var enemy_manual_debug_click: bool = debug_manual_enemy_chain_responses and chain_in_progress and chain_response_window_owner == OWNER_ENEMY and card_instance.owner == OWNER_ENEMY
    if card_instance.owner != OWNER_PLAYER and not enemy_manual_debug_click:
        return

    var is_player_response_window: bool = chain_in_progress and chain_response_window_owner == OWNER_PLAYER
    if card_instance.owner == OWNER_PLAYER and not is_player_turn and not is_player_response_window:
        return

    var menu: ActionMenu = get_tree().root.get_node_or_null("main/ActionMenu") as ActionMenu
    if menu == null:
        return

    var actions: Array[StringName] = get_available_actions(card_ui)
    menu.set_available_actions(actions)

    if actions.is_empty():
        menu.close()
        return

    var menu_position: Vector2 = _compute_action_menu_position(card_ui, menu)
    menu.open(card_ui, menu_position)

func _compute_action_menu_position(card_ui: CardUI, menu: ActionMenu) -> Vector2:
    var viewport_size: Vector2 = get_viewport().get_visible_rect().size
    var card_rect: Rect2 = card_ui.get_global_rect()

    var menu_width: float = maxf(menu.size.x, 180.0)
    var menu_height: float = maxf(menu.size.y, 310.0)
    var margin: float = 8.0

    var right_x: float = card_rect.position.x + card_rect.size.x + margin
    var left_x: float = card_rect.position.x - menu_width - margin
    var target_x: float = right_x
    if right_x + menu_width > viewport_size.x:
        target_x = left_x

    var target_y: float = card_rect.position.y
    var initial_rect: Rect2 = Rect2(Vector2(target_x, target_y), Vector2(menu_width, menu_height))

    if _rect_intersects_neighbor_hand_cards(initial_rect, card_ui):
        target_x = card_rect.position.x
        target_y = card_rect.position.y - menu_height - margin

    target_x = clampf(target_x, 0.0, maxf(0.0, viewport_size.x - menu_width))
    target_y = clampf(target_y, 0.0, maxf(0.0, viewport_size.y - menu_height))
    return Vector2(target_x, target_y)

func _rect_intersects_neighbor_hand_cards(test_rect: Rect2, source_card: CardUI) -> bool:
    var parent_node: Node = source_card.get_parent()
    if parent_node == null:
        return false

    var child_count: int = parent_node.get_child_count()
    for i: int in range(child_count):
        var sibling_card: CardUI = parent_node.get_child(i) as CardUI
        if sibling_card == null:
            continue
        if sibling_card == source_card:
            continue
        if test_rect.intersects(sibling_card.get_global_rect()):
            return true

    return false

func _begin_attack_target_selection(attacker: CardInstance, attacker_ui: CardUI, defenders: Array[CardInstance]) -> void:
    if attacker == null or defenders.is_empty():
        return

    target_selection_active = true
    target_selection_mode = TARGET_SELECTION_MODE_ATTACK
    target_selection_candidates.clear()
    for defender: CardInstance in defenders:
        target_selection_candidates.append(defender)
    pending_attack_attacker = attacker
    pending_attack_card_ui = attacker_ui
    pending_effect_link = {}
    pending_effect_rollback_context.clear()

    _refresh_target_selection_ui()
    _apply_target_selection_card_interaction()

func _begin_effect_target_selection(chain_link: Dictionary, candidates: Array[CardInstance], rollback_context: Dictionary = {}) -> bool:
    if chain_link.is_empty() or candidates.is_empty():
        return false

    target_selection_active = true
    target_selection_mode = TARGET_SELECTION_MODE_EFFECT
    target_selection_candidates.clear()
    for candidate: CardInstance in candidates:
        target_selection_candidates.append(candidate)
    pending_effect_link = chain_link.duplicate(true) as Dictionary
    pending_effect_rollback_context = rollback_context.duplicate(true) as Dictionary
    pending_attack_attacker = null
    pending_attack_card_ui = null

    _refresh_target_selection_ui()
    _apply_target_selection_card_interaction()
    return true

func _handle_target_selection_click(clicked_card: CardInstance) -> bool:
    if not target_selection_active:
        return false
    if clicked_card == null:
        return true
    if not target_selection_candidates.has(clicked_card):
        return true

    if target_selection_mode == TARGET_SELECTION_MODE_ATTACK:
        var attacker: CardInstance = pending_attack_attacker
        var attacker_ui: CardUI = pending_attack_card_ui
        _clear_target_selection_mode()
        if attacker == null:
            return true
        resolve_battle_for_attacker(attacker_ui, attacker, clicked_card)
        return true

    if target_selection_mode == TARGET_SELECTION_MODE_EFFECT:
        var selected_link: Dictionary = pending_effect_link.duplicate(true) as Dictionary
        var selected_effect: Dictionary = selected_link.get("effect", {}) as Dictionary
        selected_effect["target_instance_id"] = clicked_card.get_instance_id()
        selected_link["effect"] = selected_effect
        _clear_target_selection_mode()
        _start_chain_with_initial_link(selected_link)
        return true

    _clear_target_selection_mode()
    return true

func _clear_target_selection_mode() -> void:
    target_selection_active = false
    target_selection_mode = StringName()
    target_selection_candidates.clear()
    pending_attack_attacker = null
    pending_attack_card_ui = null
    pending_effect_link.clear()
    pending_effect_rollback_context.clear()
    _refresh_target_selection_ui()
    _refresh_chain_reactive_card_feedback()

func _on_target_selection_cancel_pressed() -> void:
    if not target_selection_active:
        return

    if target_selection_mode == TARGET_SELECTION_MODE_EFFECT:
        _rollback_pending_effect_target_selection()

    _clear_target_selection_mode()
    _run_state_based_checks()

func _rollback_pending_effect_target_selection() -> void:
    if pending_effect_rollback_context.is_empty():
        return

    var rollback_context: Dictionary = pending_effect_rollback_context.duplicate(true) as Dictionary
    _restore_effect_activation_rollback_context(rollback_context)

func _apply_target_selection_card_interaction() -> void:
    var targetable_ui: Array[CardUI] = []
    for target_card: CardInstance in target_selection_candidates:
        var target_ui: CardUI = _find_card_ui_for_instance(target_card)
        if target_ui != null:
            targetable_ui.append(target_ui)

    var all_card_uis: Array[CardUI] = _get_all_card_ui_nodes()
    for card_ui: CardUI in all_card_uis:
        if card_ui == null:
            continue

        var is_targetable: bool = targetable_ui.has(card_ui)
        _set_card_ui_target_selection_state(card_ui, target_selection_active, is_targetable)
        if is_targetable:
            card_ui.mouse_filter = Control.MOUSE_FILTER_STOP
        else:
            card_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _set_card_ui_target_selection_state(card_ui: CardUI, is_active: bool, is_targetable: bool) -> void:
    if card_ui == null:
        return

    if card_ui.has_method("set_target_selection_state"):
        card_ui.call("set_target_selection_state", is_active, is_targetable)
        return

    if is_active and not is_targetable:
        card_ui.modulate = Color(0.72, 0.72, 0.72, 1.0)
    elif is_active and is_targetable:
        card_ui.modulate = Color(0.78, 1.0, 0.78, 1.0)
    else:
        card_ui.modulate = Color(1.0, 1.0, 1.0, 1.0)

func _get_all_card_ui_nodes() -> Array[CardUI]:
    var card_nodes: Array[CardUI] = []
    for key_variant: Variant in card_instances_by_ui_id.keys():
        var ui_id: int = int(key_variant)
        var ui_object: Object = instance_from_id(ui_id)
        var card_ui: CardUI = ui_object as CardUI
        if card_ui == null:
            continue
        card_nodes.append(card_ui)
    return card_nodes

func _get_attack_target_candidates(state: Dictionary) -> Array[CardInstance]:
    var candidates: Array[CardInstance] = []
    if state.is_empty():
        return candidates

    var monster_slots: Array = state[ZONE_KEY_MONSTER] as Array
    for slot_item: Variant in monster_slots:
        var monster: CardInstance = slot_item as CardInstance
        if monster == null:
            continue
        candidates.append(monster)
    return candidates

func get_available_actions(card_ui: CardUI) -> Array[StringName]:
    var card_instance: RefCounted = _get_card_instance(card_ui)
    return get_available_actions_for_card(card_instance)

func get_available_actions_for_card(card_instance: RefCounted, context_override: Dictionary = {}) -> Array[StringName]:
    if duel_has_ended:
        return []
    if card_instance == null:
        return []

    var context: Dictionary = _build_action_context(card_instance.owner)
    for key: Variant in context_override.keys():
        context[key] = context_override[key]

    return rule_engine.get_available_actions(card_instance, context)

func _build_action_context(card_owner: int) -> Dictionary:
    var owner_state: Dictionary = _get_state_by_owner(card_owner)
    var opponent_owner: int = OWNER_ENEMY if card_owner == OWNER_PLAYER else OWNER_PLAYER
    var opponent_state: Dictionary = _get_state_by_owner(opponent_owner)
    var opponent_has_monsters: bool = _has_any_monster(opponent_state)

    var active_owner_for_actions: int = _get_active_owner()
    var in_response_window: bool = false
    if chain_in_progress and chain_response_window_owner == card_owner:
        active_owner_for_actions = card_owner
        in_response_window = true

    var context: Dictionary = {
        RuleEngine.CONTEXT_ACTIVE_OWNER: active_owner_for_actions,
        RuleEngine.CONTEXT_IS_PLAYER_TURN: is_player_turn,
        RuleEngine.CONTEXT_CURRENT_PHASE: current_phase,
        RuleEngine.CONTEXT_NORMAL_SUMMON_USED: not turn_manager.can_normal_summon() if turn_manager != null else false,
        RuleEngine.CONTEXT_HAS_FREE_MONSTER_ZONE: _has_free_monster_zone(owner_state),
        RuleEngine.CONTEXT_HAS_FREE_SPELL_TRAP_ZONE: _has_free_spell_zone(owner_state),
        RuleEngine.CONTEXT_OPPONENT_HAS_MONSTERS: opponent_has_monsters,
        RuleEngine.CONTEXT_HAS_ATTACK_TARGET: true if not opponent_has_monsters else _get_first_attack_target(opponent_state) != null,
        RuleEngine.CONTEXT_CHAIN_IN_PROGRESS: chain_in_progress,
        RuleEngine.CONTEXT_CHAIN_MIN_RESPONSE_SPEED: chain_min_response_speed,
        RuleEngine.CONTEXT_IN_RESPONSE_WINDOW: in_response_window,
    }
    return context

func _is_main_phase() -> bool:
    return current_phase == PHASE_MAIN_1 or current_phase == PHASE_MAIN_2

func execute_action(action: StringName, card_ui: CardUI) -> bool:
    if duel_has_ended:
        return false
    if card_ui == null:
        return false

    var card_instance: RefCounted = _get_card_instance(card_ui)
    if card_instance == null:
        return false

    var available_actions: Array[StringName] = get_available_actions_for_card(card_instance)
    if not available_actions.has(action):
        return false

    return action_resolver.execute_action(action, card_ui, card_instance, self)

func execute_action_for_instance(action: StringName, card_instance: RefCounted) -> bool:
    if duel_has_ended:
        return false
    if card_instance == null:
        return false

    var available_actions: Array[StringName] = get_available_actions_for_card(card_instance)
    if not available_actions.has(action):
        return false

    var card_ui: CardUI = _find_card_ui_for_instance(card_instance)
    return action_resolver.execute_action(action, card_ui, card_instance, self)

func notify_activate(card_instance: RefCounted, action: StringName) -> void:
    if card_instance == null:
        return
    emit_signal("on_activate", card_instance, action)

func notify_resolve(card_instance: RefCounted, action: StringName, success: bool) -> void:
    if card_instance == null:
        return
    emit_signal("on_resolve", card_instance, action, success)

func handle_spell_trap_activation(action: StringName, card_ui: CardUI, card_instance: RefCounted) -> bool:
    if duel_has_ended:
        return false
    if card_instance == null:
        return false

    var typed_card: CardInstance = card_instance as CardInstance
    if typed_card == null:
        return false

    if chain_in_progress:
        return _handle_chain_response_activation(action, card_ui, typed_card)

    var rollback_context: Dictionary = _capture_effect_activation_rollback_context(typed_card, action)

    if not _prepare_card_for_spell_trap_activation(action, card_ui, typed_card):
        return false

    typed_card.mark_activated_this_turn()

    var activation_speed: int = maxi(1, effect_resolver.get_activation_speed(typed_card))
    var initial_link: Dictionary = _make_chain_link(typed_card, action, activation_speed)
    var requires_interactive_target: bool = _should_prompt_player_for_effect_target(initial_link)
    if requires_interactive_target:
        var selectable_targets: Array[CardInstance] = _get_selectable_targets_for_effect_link(initial_link)
        if selectable_targets.is_empty():
            _restore_effect_activation_rollback_context(rollback_context)
            _run_state_based_checks()
            return false

        if _begin_effect_target_selection(initial_link, selectable_targets, rollback_context):
            _run_state_based_checks()
            return true

    _start_chain_with_initial_link(initial_link)
    _run_state_based_checks()
    return true

func _capture_effect_activation_rollback_context(card_instance: CardInstance, action: StringName) -> Dictionary:
    if card_instance == null:
        return {}

    return {
        "action": action,
        "card_instance": card_instance,
        "previous_zone": card_instance.current_zone,
        "previous_slot": card_instance.zone_slot_index,
        "previous_face_up": card_instance.face_up,
        "previous_has_activated_this_turn": card_instance.has_activated_this_turn,
    }

func _restore_effect_activation_rollback_context(rollback_context: Dictionary) -> void:
    if rollback_context.is_empty():
        return

    var card_instance: CardInstance = rollback_context.get("card_instance") as CardInstance
    if card_instance == null:
        return

    var previous_zone: int = int(rollback_context.get("previous_zone", card_instance.current_zone))
    var previous_slot: int = int(rollback_context.get("previous_slot", card_instance.zone_slot_index))
    var previous_face_up: bool = bool(rollback_context.get("previous_face_up", card_instance.face_up))
    var previous_has_activated: bool = bool(rollback_context.get("previous_has_activated_this_turn", card_instance.has_activated_this_turn))

    if card_instance.current_zone != previous_zone or card_instance.zone_slot_index != previous_slot:
        var restore_card_ui: CardUI = _find_card_ui_for_instance(card_instance)
        move_card_to_zone(restore_card_ui, card_instance, previous_zone, previous_slot)

    card_instance.face_up = previous_face_up
    card_instance.has_activated_this_turn = previous_has_activated
    var synced_card_ui: CardUI = _find_card_ui_for_instance(card_instance)
    sync_card_ui_from_instance(synced_card_ui, card_instance)

func pass_chain_response_for_player() -> void:
    if duel_has_ended:
        return
    if not chain_in_progress:
        return
    if chain_response_window_owner != OWNER_PLAYER:
        return

    _register_chain_pass(OWNER_PLAYER)
    _continue_chain_building_or_resolve()
    _run_state_based_checks()

func pass_chain_response_for_enemy_debug() -> void:
    if duel_has_ended:
        return
    if not chain_in_progress:
        return
    if not debug_manual_enemy_chain_responses:
        return
    if chain_response_window_owner != OWNER_ENEMY:
        return

    _register_chain_pass(OWNER_ENEMY)
    _continue_chain_building_or_resolve()
    _run_state_based_checks()

func _handle_chain_response_activation(action: StringName, card_ui: CardUI, card_instance: CardInstance) -> bool:
    if not chain_in_progress:
        return false
    if action != ACTION_ACTIVATE_SET_SPELL_TRAP:
        return false
    if card_instance.owner != chain_response_window_owner:
        return false

    if not _prepare_card_for_spell_trap_activation(action, card_ui, card_instance):
        return false

    card_instance.mark_activated_this_turn()
    var response_speed: int = maxi(1, effect_resolver.get_activation_speed(card_instance))
    var response_link: Dictionary = _make_chain_link(card_instance, action, response_speed)
    _append_chain_response_link(response_link)
    _continue_chain_building_or_resolve()
    _run_state_based_checks()
    return true

func _prepare_card_for_spell_trap_activation(action: StringName, card_ui: CardUI, card_instance: CardInstance) -> bool:
    if action == ACTION_ACTIVATE_SPELL:
        var slot_index: int = get_first_free_slot(card_instance.owner, CARD_ZONE_SPELL_TRAP)
        if slot_index < 0:
            return false
        if not move_card_to_zone(card_ui, card_instance, CARD_ZONE_SPELL_TRAP, slot_index):
            return false
    elif action == ACTION_ACTIVATE_SET_SPELL_TRAP:
        if card_instance.current_zone != CARD_ZONE_SPELL_TRAP:
            return false
    else:
        return false

    card_instance.face_up = true
    sync_card_ui_from_instance(card_ui, card_instance)
    return true

func _make_chain_link(card_instance: CardInstance, action: StringName, speed: int) -> Dictionary:
    var effect: Dictionary = effect_resolver.create_effect_for_card(card_instance, action) as Dictionary
    return {
        "card_instance": card_instance,
        "action": action,
        "speed": speed,
        "effect": effect,
        "owner": card_instance.owner,
    }

func _start_chain_with_initial_link(initial_link: Dictionary) -> void:
    if initial_link.is_empty():
        return

    chain_links.clear()
    chain_links.append(initial_link)
    chain_in_progress = true
    chain_pass_count = 0
    chain_min_response_speed = int(initial_link.get("speed", 1))
    var owner_id: int = int(initial_link.get("owner", OWNER_PLAYER))
    chain_response_window_owner = get_opponent_owner(owner_id)
    emit_signal("chain_state_changed", chain_links.size(), false)
    _refresh_chain_panel_ui()
    _continue_chain_building_or_resolve()

func _should_prompt_player_for_effect_target(chain_link: Dictionary) -> bool:
    if chain_link.is_empty():
        return false
    if not is_inside_tree():
        return false

    var owner_id: int = int(chain_link.get("owner", OWNER_PLAYER))
    if owner_id != OWNER_PLAYER:
        return false

    var effect: Dictionary = chain_link.get("effect", {}) as Dictionary
    return _effect_requires_target_selection(effect)

func _effect_requires_target_selection(effect: Dictionary) -> bool:
    if effect.is_empty():
        return false

    var operation: StringName = StringName(effect.get("operation", StringName()))
    return operation == StringName("destroy_one_opponent_monster") \
        or operation == StringName("destroy_one_opponent_spell_trap") \
        or operation == StringName("set_one_opponent_monster_face_down") \
        or operation == StringName("set_one_opponent_monster_defense") \
        or operation == StringName("banish_one_opponent_monster") \
        or operation == StringName("return_one_opponent_monster_to_hand")

func _get_selectable_targets_for_effect_link(chain_link: Dictionary) -> Array[CardInstance]:
    var candidates: Array[CardInstance] = []
    if chain_link.is_empty():
        return candidates

    var owner_id: int = int(chain_link.get("owner", OWNER_PLAYER))
    var opponent_owner: int = get_opponent_owner(owner_id)
    var effect: Dictionary = chain_link.get("effect", {}) as Dictionary
    var operation: StringName = StringName(effect.get("operation", StringName()))

    if operation == StringName("destroy_one_opponent_spell_trap"):
        var opponent_state_spell: Dictionary = _get_state_by_owner(opponent_owner)
        var spell_slots: Array = opponent_state_spell[ZONE_KEY_SPELL_TRAP] as Array
        for slot_item: Variant in spell_slots:
            var spell_target: CardInstance = slot_item as CardInstance
            if spell_target == null:
                continue
            candidates.append(spell_target)
        return candidates

    if operation == StringName("destroy_one_opponent_monster") \
        or operation == StringName("set_one_opponent_monster_face_down") \
        or operation == StringName("set_one_opponent_monster_defense") \
        or operation == StringName("banish_one_opponent_monster") \
        or operation == StringName("return_one_opponent_monster_to_hand"):
        var opponent_state_monster: Dictionary = _get_state_by_owner(opponent_owner)
        return _get_attack_target_candidates(opponent_state_monster)

    return candidates

func _append_chain_response_link(response_link: Dictionary) -> void:
    chain_links.append(response_link)
    chain_min_response_speed = int(response_link.get("speed", 1))

    var responder_owner: int = int(response_link.get("owner", OWNER_PLAYER))
    chain_response_window_owner = get_opponent_owner(responder_owner)
    chain_pass_count = 0

    var response_card: CardInstance = response_link.get("card_instance") as CardInstance
    if response_card != null:
        notify_activate(response_card, StringName(response_link.get("action", StringName())))

    emit_signal("chain_state_changed", chain_links.size(), false)
    _refresh_chain_panel_ui()

func _continue_chain_building_or_resolve() -> void:
    var safety_steps: int = 0
    while chain_in_progress and not duel_has_ended and safety_steps < 40:
        safety_steps += 1

        if chain_pass_count >= 2:
            _resolve_and_clear_chain()
            return

        if chain_response_window_owner == OWNER_ENEMY:
            if debug_manual_enemy_chain_responses:
                var enemy_can_respond: bool = _has_available_response_for_owner(OWNER_ENEMY)
                if not enemy_can_respond:
                    _register_chain_pass(OWNER_ENEMY)
                    continue

                _refresh_chain_panel_ui()
                return

            var enemy_response_link: Dictionary = _find_auto_response_chain_link(OWNER_ENEMY)
            if enemy_response_link.is_empty():
                _register_chain_pass(OWNER_ENEMY)
                continue

            _append_chain_response_link(enemy_response_link)
            continue

        var player_can_respond: bool = _has_available_response_for_owner(OWNER_PLAYER)
        if not player_can_respond:
            _register_chain_pass(OWNER_PLAYER)
            continue

        _refresh_chain_panel_ui()
        return

    if chain_in_progress and not duel_has_ended:
        _resolve_and_clear_chain()

func _register_chain_pass(owner_id: int) -> void:
    chain_pass_count += 1
    chain_response_window_owner = get_opponent_owner(owner_id)
    _refresh_chain_panel_ui()

    if chain_pass_count >= 2 and chain_in_progress:
        _resolve_and_clear_chain()

func _resolve_and_clear_chain() -> void:
    if not chain_links.is_empty():
        _resolve_current_chain()

    chain_links.clear()
    chain_in_progress = false
    chain_pass_count = 0
    chain_min_response_speed = 1
    chain_response_window_owner = _get_active_owner()
    emit_signal("chain_state_changed", 0, false)
    _refresh_chain_panel_ui()

func _has_available_response_for_owner(owner_id: int) -> bool:
    var owner_state: Dictionary = _get_state_by_owner(owner_id)
    var spell_slots: Array = owner_state[ZONE_KEY_SPELL_TRAP] as Array

    for slot_item: Variant in spell_slots:
        var card_instance: CardInstance = slot_item as CardInstance
        if card_instance == null:
            continue

        var actions: Array[StringName] = get_available_actions_for_card(card_instance)
        if actions.has(ACTION_ACTIVATE_SET_SPELL_TRAP):
            return true

    return false

func _find_auto_response_chain_link(owner_id: int) -> Dictionary:
    var owner_state: Dictionary = _get_state_by_owner(owner_id)
    var spell_slots: Array = owner_state[ZONE_KEY_SPELL_TRAP] as Array

    for slot_item: Variant in spell_slots:
        var card_instance: CardInstance = slot_item as CardInstance
        if card_instance == null:
            continue

        var actions: Array[StringName] = get_available_actions_for_card(card_instance)
        if not actions.has(ACTION_ACTIVATE_SET_SPELL_TRAP):
            continue

        card_instance.face_up = true
        card_instance.mark_activated_this_turn()
        var card_ui: CardUI = _find_card_ui_for_instance(card_instance)
        sync_card_ui_from_instance(card_ui, card_instance)

        var speed: int = maxi(1, effect_resolver.get_activation_speed(card_instance))
        return _make_chain_link(card_instance, ACTION_ACTIVATE_SET_SPELL_TRAP, speed)

    return {}

func _resolve_current_chain() -> bool:
    if chain_links.is_empty():
        return false

    emit_signal("chain_state_changed", chain_links.size(), true)

    var any_success: bool = false
    for reverse_index: int in range(chain_links.size() - 1, -1, -1):
        if duel_has_ended:
            break

        var link: Dictionary = chain_links[reverse_index]
        var card_instance: CardInstance = link.get("card_instance") as CardInstance
        var action: StringName = StringName(link.get("action", StringName()))
        var effect: Dictionary = link.get("effect", {}) as Dictionary

        if card_instance == null:
            continue

        var was_negated: bool = bool(link.get("negated", false))
        var success: bool = false
        if not was_negated:
            success = effect_resolver.resolve_effect(effect, self, reverse_index)

        var should_send_after_resolve: bool = effect_resolver.should_send_to_grave_after_resolve(card_instance)
        var should_send_negated_activation: bool = was_negated and _is_chain_activation_action(action) and card_instance.is_spell_or_trap()
        if should_send_after_resolve or should_send_negated_activation:
            var send_reason: StringName = &"spell_resolve"
            if should_send_negated_activation:
                send_reason = &"negated_activation"
            send_to_grave(null, card_instance, send_reason)

        _play_chain_resolve_flash(int(link.get("owner", OWNER_PLAYER)))

        var resolved_card_name: String = str(card_instance.card_data.get("name", "Unknown"))
        var result_text: String = "negated" if was_negated else ("resolved" if success else "no effect")
        _push_chain_history_line("Resolve CL%d %s -> %s" % [reverse_index + 1, resolved_card_name, result_text])

        if reverse_index != 0:
            notify_resolve(card_instance, action, success)

        if success:
            any_success = true

    return any_success

func send_to_grave(card_ui: CardUI, card_instance: RefCounted, reason: StringName = &"") -> bool:
    if duel_has_ended:
        return false
    if card_instance == null:
        return false

    var moved: bool = move_card_to_zone(card_ui, card_instance, CARD_ZONE_GRAVEYARD)
    if not moved:
        return false

    emit_signal("on_send_to_grave", card_instance, reason)
    return true

func destroy_card(card_ui: CardUI, card_instance: RefCounted, reason: StringName = &"") -> bool:
    if duel_has_ended:
        return false
    if card_instance == null:
        return false

    var moved: bool = send_to_grave(card_ui, card_instance, reason)
    if not moved:
        return false

    emit_signal("on_destroy", card_instance, reason)
    return true

func banish_card(card_ui: CardUI, card_instance: RefCounted, reason: StringName = &"") -> bool:
    if duel_has_ended:
        return false
    if card_instance == null:
        return false

    var moved: bool = move_card_to_zone(card_ui, card_instance, CARD_ZONE_BANISHED)
    if not moved:
        return false

    emit_signal("on_banish", card_instance, reason)
    return true

func normal_summon(card_ui: CardUI) -> void:
    execute_action(ACTION_NORMAL_SUMMON, card_ui)

func set_summon(card_ui: CardUI) -> void:
    execute_action(ACTION_SET_MONSTER, card_ui)

func activate_spell(card_ui: CardUI) -> void:
    execute_action(ACTION_ACTIVATE_SPELL, card_ui)

func activate_set_spell_trap(card_ui: CardUI) -> void:
    execute_action(ACTION_ACTIVATE_SET_SPELL_TRAP, card_ui)

func set_spell(card_ui: CardUI) -> void:
    execute_action(ACTION_SET_SPELL, card_ui)

func position_change(card_ui: CardUI) -> void:
    execute_action(ACTION_POS_CHANGE, card_ui)

func flip_summon(card_ui: CardUI) -> void:
    execute_action(ACTION_FLIP_SUMMON, card_ui)

func declare_attack(card_ui: CardUI) -> void:
    if card_ui == null:
        return

    var attacker_instance: CardInstance = _get_card_instance(card_ui) as CardInstance
    if attacker_instance == null:
        return

    var should_use_interactive_selection: bool = attacker_instance.owner == OWNER_PLAYER and is_inside_tree() and is_player_turn
    if should_use_interactive_selection:
        var opponent_state: Dictionary = _get_state_by_owner(get_opponent_owner(attacker_instance.owner))
        var defenders: Array[CardInstance] = _get_attack_target_candidates(opponent_state)
        if not defenders.is_empty():
            _begin_attack_target_selection(attacker_instance, card_ui, defenders)
            return

    execute_action(ACTION_DECLARE_ATTACK, card_ui)

func is_direct_attack_available_for_card_ui(card_ui: CardUI) -> bool:
    if card_ui == null:
        return false

    var card_instance: CardInstance = _get_card_instance(card_ui) as CardInstance
    return is_direct_attack_available_for_instance(card_instance)

func is_direct_attack_available_for_instance(card_instance: CardInstance) -> bool:
    if card_instance == null:
        return false

    var available_actions: Array[StringName] = get_available_actions_for_card(card_instance)
    if not available_actions.has(ACTION_DECLARE_ATTACK):
        return false

    var opponent_owner: int = get_opponent_owner(card_instance.owner)
    var opponent_state: Dictionary = _get_state_by_owner(opponent_owner)
    var defenders: Array[CardInstance] = _get_attack_target_candidates(opponent_state)
    return defenders.is_empty()

func get_life_points(owner_id: int) -> int:
    var state: Dictionary = _get_state_by_owner(owner_id)
    return int(state.get(STATE_KEY_LIFE_POINTS, START_LIFE_POINTS))

func get_opponent_owner(owner_id: int) -> int:
    return OWNER_ENEMY if owner_id == OWNER_PLAYER else OWNER_PLAYER

func is_card_still_on_field(card_instance: CardInstance) -> bool:
    if card_instance == null:
        return false
    return card_instance.current_zone == CARD_ZONE_MONSTER or card_instance.current_zone == CARD_ZONE_SPELL_TRAP

func draw_cards_for_owner(owner_id: int, amount: int) -> bool:
    var target_state: Dictionary = _get_state_by_owner(owner_id)
    var should_spawn_ui: bool = owner_id == OWNER_PLAYER
    var cards_to_draw: int = maxi(0, amount)

    for draw_index: int in range(cards_to_draw):
        var drawn_card: RefCounted = _draw_one_card(target_state, should_spawn_ui)
        if drawn_card == null:
            return false
        if duel_has_ended:
            return false

    return true

func apply_life_point_damage(owner_id: int, amount: int) -> void:
    _apply_life_point_damage(owner_id, amount)

func gain_life_points(owner_id: int, amount: int) -> void:
    if duel_has_ended:
        return

    var clamped_amount: int = maxi(0, amount)
    var state: Dictionary = _get_state_by_owner(owner_id)
    var current_lp: int = int(state.get(STATE_KEY_LIFE_POINTS, START_LIFE_POINTS))
    state[STATE_KEY_LIFE_POINTS] = current_lp + clamped_amount
    _run_state_based_checks()

func get_first_monster_for_owner(owner_id: int) -> CardInstance:
    var state: Dictionary = _get_state_by_owner(owner_id)
    var monster_slots: Array = state[ZONE_KEY_MONSTER] as Array
    for slot_item: Variant in monster_slots:
        var card_instance: CardInstance = slot_item as CardInstance
        if card_instance == null:
            continue
        return card_instance
    return null

func get_all_field_monsters() -> Array[CardInstance]:
    var monsters: Array[CardInstance] = []

    var player_monsters: Array = player_state[ZONE_KEY_MONSTER] as Array
    for slot_item: Variant in player_monsters:
        var player_card: CardInstance = slot_item as CardInstance
        if player_card != null:
            monsters.append(player_card)

    var enemy_monsters: Array = enemy_state[ZONE_KEY_MONSTER] as Array
    for slot_item: Variant in enemy_monsters:
        var enemy_card: CardInstance = slot_item as CardInstance
        if enemy_card != null:
            monsters.append(enemy_card)

    return monsters

func get_first_spell_trap_for_owner(owner_id: int) -> CardInstance:
    var state: Dictionary = _get_state_by_owner(owner_id)
    var spell_slots: Array = state[ZONE_KEY_SPELL_TRAP] as Array
    for slot_item: Variant in spell_slots:
        var card_instance: CardInstance = slot_item as CardInstance
        if card_instance == null:
            continue
        return card_instance
    return null

func set_monster_face_down(monster: CardInstance) -> bool:
    if monster == null:
        return false
    if monster.current_zone != CARD_ZONE_MONSTER:
        return false

    monster.face_up = false
    monster.battle_position = BATTLE_POSITION_DEFENSE
    var card_ui: CardUI = _find_card_ui_for_instance(monster)
    sync_card_ui_from_instance(card_ui, monster)
    return true

func set_monster_to_defense(monster: CardInstance) -> bool:
    if monster == null:
        return false
    if monster.current_zone != CARD_ZONE_MONSTER:
        return false

    monster.battle_position = BATTLE_POSITION_DEFENSE
    var card_ui: CardUI = _find_card_ui_for_instance(monster)
    sync_card_ui_from_instance(card_ui, monster)
    return true

func negate_next_chain_link_from(current_link_index: int) -> bool:
    if current_link_index <= 0:
        return false

    for link_index: int in range(current_link_index - 1, -1, -1):
        var chain_link: Dictionary = chain_links[link_index] as Dictionary
        if chain_link.is_empty():
            continue
        if bool(chain_link.get("negated", false)):
            continue

        chain_link["negated"] = true
        chain_links[link_index] = chain_link
        return true

    return false

func destroy_card_instance(card_instance: CardInstance, reason: StringName = &"effect") -> bool:
    if card_instance == null:
        return false

    var card_ui: CardUI = _find_card_ui_for_instance(card_instance)
    return action_resolver.destroy_card(card_ui, card_instance, self, reason)

func surrender(owner_id: int) -> void:
    if duel_has_ended:
        return

    var winner: int = OWNER_ENEMY if owner_id == OWNER_PLAYER else OWNER_PLAYER
    _end_duel(winner, RESULT_REASON_SURRENDER)

func _run_state_based_checks() -> void:
    if duel_has_ended:
        _refresh_life_point_display()
        return

    _normalize_state_arrays(player_state)
    _normalize_state_arrays(enemy_state)
    _correct_zone_membership_for_owner(player_state, OWNER_PLAYER)
    _correct_zone_membership_for_owner(enemy_state, OWNER_ENEMY)
    _refresh_life_point_display()

    var player_lp: int = get_life_points(OWNER_PLAYER)
    var enemy_lp: int = get_life_points(OWNER_ENEMY)

    if player_lp <= 0 and enemy_lp <= 0:
        _end_duel(OWNER_DRAW, RESULT_REASON_DRAW)
        return
    if player_lp <= 0:
        _end_duel(OWNER_ENEMY, RESULT_REASON_LIFE_POINTS)
        return
    if enemy_lp <= 0:
        _end_duel(OWNER_PLAYER, RESULT_REASON_LIFE_POINTS)

func _try_start_enemy_turn() -> void:
    if duel_has_ended:
        return
    if not enable_simple_enemy_ai:
        return
    if is_player_turn:
        return
    if enemy_turn_in_progress:
        return
    if not is_inside_tree():
        return

    enemy_turn_in_progress = true
    _refresh_phase_display()
    call_deferred("_run_simple_enemy_turn")

func _run_simple_enemy_turn() -> void:
    if _enemy_ai_should_abort_turn():
        return

    await _enemy_ai_wait_step()
    if _enemy_ai_should_abort_turn():
        return

    set_current_phase(PHASE_STANDBY)
    await _enemy_ai_wait_step()
    if _enemy_ai_should_abort_turn():
        return

    set_current_phase(PHASE_MAIN_1)
    await _enemy_ai_execute_main_phase_actions(8)
    if _enemy_ai_should_abort_turn():
        return

    set_current_phase(PHASE_BATTLE)
    await _enemy_ai_execute_battle_phase_actions()
    if _enemy_ai_should_abort_turn():
        return

    set_current_phase(PHASE_MAIN_2)
    await _enemy_ai_execute_main_phase_actions(5)
    if _enemy_ai_should_abort_turn():
        return

    set_current_phase(PHASE_END)
    await _enemy_ai_wait_step()

    enemy_turn_in_progress = false
    _refresh_phase_display()

    if duel_has_ended:
        return

    _finalize_turn_for_owner(OWNER_ENEMY)
    turn_manager.next_turn()
    is_player_turn = turn_manager.is_player_turn()
    _start_turn_draw_step()

func _enemy_ai_should_abort_turn() -> bool:
    if duel_has_ended or is_player_turn:
        enemy_turn_in_progress = false
        _refresh_phase_display()
        return true
    return false

func _enemy_ai_execute_main_phase_actions(max_actions: int) -> void:
    var safety_limit: int = maxi(1, max_actions)
    for action_index: int in range(safety_limit):
        if duel_has_ended or is_player_turn:
            return

        var action_taken: bool = false
        if _simple_enemy_try_set_trap_from_hand():
            action_taken = true
        elif _simple_enemy_try_activate_spell_from_hand():
            action_taken = true
        elif _simple_enemy_try_normal_summon_attack_position():
            action_taken = true
        elif _simple_enemy_try_set_spell_from_hand():
            action_taken = true

        if not action_taken:
            return

        await _enemy_ai_wait_for_chain_resolution()
        if duel_has_ended or is_player_turn:
            return
        await _enemy_ai_wait_step()

func _enemy_ai_execute_battle_phase_actions() -> void:
    var safety_limit: int = 8
    for attack_index: int in range(safety_limit):
        if duel_has_ended or is_player_turn:
            return

        var attacker: CardInstance = _simple_enemy_get_next_attack_ready_monster()
        if attacker == null:
            return

        var attack_success: bool = execute_action_for_instance(ACTION_DECLARE_ATTACK, attacker)
        if not attack_success:
            return

        if duel_has_ended or is_player_turn:
            return
        await _enemy_ai_wait_step()

func _enemy_ai_wait_for_chain_resolution() -> void:
    var safety_frames: int = 0
    while chain_in_progress and not duel_has_ended and safety_frames < 1200:
        safety_frames += 1
        await get_tree().process_frame

func _enemy_ai_wait_step() -> void:
    if enemy_ai_step_delay <= 0.0:
        await get_tree().process_frame
        return

    var timer: SceneTreeTimer = get_tree().create_timer(enemy_ai_step_delay)
    await timer.timeout

func _simple_enemy_try_normal_summon_attack_position() -> bool:
    var enemy_hand: Array = enemy_state[ZONE_KEY_HAND] as Array
    for hand_item: Variant in enemy_hand:
        var hand_card: RefCounted = hand_item as RefCounted
        if hand_card == null:
            continue
        if not hand_card.is_monster():
            continue

        var available_actions: Array[StringName] = get_available_actions_for_card(hand_card)
        if not available_actions.has(ACTION_NORMAL_SUMMON):
            continue

        return execute_action_for_instance(ACTION_NORMAL_SUMMON, hand_card)

    return false

func _simple_enemy_try_activate_spell_from_hand() -> bool:
    var enemy_hand: Array = enemy_state[ZONE_KEY_HAND] as Array
    for hand_item: Variant in enemy_hand:
        var hand_card: RefCounted = hand_item as RefCounted
        if hand_card == null:
            continue
        if not hand_card.is_spell_or_trap():
            continue

        var card_data: Dictionary = hand_card.card_data as Dictionary
        var card_type: String = str(card_data.get("card_type", ""))
        if card_type == "trap":
            continue

        var available_actions: Array[StringName] = get_available_actions_for_card(hand_card)
        if not available_actions.has(ACTION_ACTIVATE_SPELL):
            continue

        return execute_action_for_instance(ACTION_ACTIVATE_SPELL, hand_card)

    return false

func _simple_enemy_try_set_trap_from_hand() -> bool:
    var enemy_hand: Array = enemy_state[ZONE_KEY_HAND] as Array
    for hand_item: Variant in enemy_hand:
        var hand_card: RefCounted = hand_item as RefCounted
        if hand_card == null:
            continue
        if not hand_card.is_spell_or_trap():
            continue

        var card_data: Dictionary = hand_card.card_data as Dictionary
        var card_type: String = str(card_data.get("card_type", ""))
        if card_type != "trap":
            continue

        var available_actions: Array[StringName] = get_available_actions_for_card(hand_card)
        if not available_actions.has(ACTION_SET_SPELL):
            continue

        return execute_action_for_instance(ACTION_SET_SPELL, hand_card)

    return false

func _simple_enemy_try_set_spell_from_hand() -> bool:
    var enemy_hand: Array = enemy_state[ZONE_KEY_HAND] as Array
    for hand_item: Variant in enemy_hand:
        var hand_card: RefCounted = hand_item as RefCounted
        if hand_card == null:
            continue
        if not hand_card.is_spell_or_trap():
            continue

        var card_data: Dictionary = hand_card.card_data as Dictionary
        var card_type: String = str(card_data.get("card_type", ""))
        if card_type == "trap":
            continue

        var available_actions: Array[StringName] = get_available_actions_for_card(hand_card)
        if not available_actions.has(ACTION_SET_SPELL):
            continue

        return execute_action_for_instance(ACTION_SET_SPELL, hand_card)

    return false

func _simple_enemy_get_next_attack_ready_monster() -> CardInstance:
    var monster_slots: Array = enemy_state[ZONE_KEY_MONSTER] as Array
    for slot_item: Variant in monster_slots:
        var monster: CardInstance = slot_item as CardInstance
        if monster == null:
            continue

        var available_actions: Array[StringName] = get_available_actions_for_card(monster)
        if available_actions.has(ACTION_DECLARE_ATTACK):
            return monster

    return null

func _refresh_life_point_display() -> void:
    if player_lp_label != null:
        player_lp_label.text = "Your LP: %d" % get_life_points(OWNER_PLAYER)
    if enemy_lp_label != null:
        enemy_lp_label.text = "Enemy LP: %d" % get_life_points(OWNER_ENEMY)

func _setup_chain_panel_ui() -> void:
    var parent_control: Control = get_parent() as Control
    if parent_control == null:
        return

    chain_vfx_overlay = ColorRect.new()
    chain_vfx_overlay.name = "ChainResolveFlashOverlay"
    chain_vfx_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    chain_vfx_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
    chain_vfx_overlay.color = Color(1.0, 1.0, 1.0, 0.0)
    chain_vfx_overlay.z_index = 500
    parent_control.add_child(chain_vfx_overlay)

    chain_panel = PanelContainer.new()
    chain_panel.name = "ChainPanelRuntime"
    chain_panel.position = Vector2(16.0, 16.0)
    chain_panel.size = Vector2(520.0, 280.0)
    chain_panel.z_index = 600
    parent_control.add_child(chain_panel)

    var vbox: VBoxContainer = VBoxContainer.new()
    vbox.name = "VBox"
    vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    chain_panel.add_child(vbox)

    chain_status_label = Label.new()
    chain_status_label.name = "StatusLabel"
    chain_status_label.text = "Chain: Idle"
    vbox.add_child(chain_status_label)

    chain_response_label = Label.new()
    chain_response_label.name = "ResponseLabel"
    chain_response_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    vbox.add_child(chain_response_label)

    chain_debug_label = Label.new()
    chain_debug_label.name = "DebugLabel"
    chain_debug_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    vbox.add_child(chain_debug_label)

    var button_row: HBoxContainer = HBoxContainer.new()
    button_row.name = "ButtonRow"
    vbox.add_child(button_row)

    chain_pass_button = Button.new()
    chain_pass_button.name = "PassButton"
    chain_pass_button.text = "Pass Chain"
    chain_pass_button.visible = false
    chain_pass_button.pressed.connect(_on_chain_pass_button_pressed)
    button_row.add_child(chain_pass_button)

    chain_enemy_pass_button = Button.new()
    chain_enemy_pass_button.name = "EnemyPassButton"
    chain_enemy_pass_button.text = "Enemy Pass (Debug)"
    chain_enemy_pass_button.visible = false
    chain_enemy_pass_button.pressed.connect(_on_chain_enemy_pass_button_pressed)
    button_row.add_child(chain_enemy_pass_button)

    var stack_title_label: Label = Label.new()
    stack_title_label.name = "StackTitleLabel"
    stack_title_label.text = "Chain Stack"
    vbox.add_child(stack_title_label)

    chain_stack_scroll = ScrollContainer.new()
    chain_stack_scroll.name = "ChainStackScroll"
    chain_stack_scroll.custom_minimum_size = Vector2(500.0, 92.0)
    chain_stack_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    chain_stack_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
    vbox.add_child(chain_stack_scroll)

    chain_stack_vbox = VBoxContainer.new()
    chain_stack_vbox.name = "ChainStackVBox"
    chain_stack_vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    chain_stack_scroll.add_child(chain_stack_vbox)

    chain_history_label = Label.new()
    chain_history_label.name = "HistoryLabel"
    chain_history_label.custom_minimum_size = Vector2(500.0, 84.0)
    chain_history_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    vbox.add_child(chain_history_label)

    _refresh_chain_panel_ui()

func _setup_target_selection_ui() -> void:
    var parent_control: Control = get_parent() as Control
    if parent_control == null:
        return

    target_selection_panel = PanelContainer.new()
    target_selection_panel.name = "TargetSelectionPanelRuntime"
    target_selection_panel.position = Vector2(560.0, 16.0)
    target_selection_panel.size = Vector2(360.0, 108.0)
    target_selection_panel.visible = false
    target_selection_panel.z_index = 620
    parent_control.add_child(target_selection_panel)

    var vbox: VBoxContainer = VBoxContainer.new()
    vbox.name = "VBox"
    vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    target_selection_panel.add_child(vbox)

    target_selection_label = Label.new()
    target_selection_label.name = "TargetSelectionLabel"
    target_selection_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    target_selection_label.text = ""
    vbox.add_child(target_selection_label)

    target_selection_cancel_button = Button.new()
    target_selection_cancel_button.name = "TargetSelectionCancelButton"
    target_selection_cancel_button.text = "Cancel"
    target_selection_cancel_button.pressed.connect(_on_target_selection_cancel_pressed)
    vbox.add_child(target_selection_cancel_button)

func _refresh_target_selection_ui() -> void:
    if target_selection_panel == null:
        return

    target_selection_panel.visible = target_selection_active
    if target_selection_label == null:
        return

    if not target_selection_active:
        target_selection_label.text = ""
        if target_selection_cancel_button != null:
            target_selection_cancel_button.disabled = true
        return

    if target_selection_mode == TARGET_SELECTION_MODE_ATTACK:
        target_selection_label.text = "Select an opponent monster to attack, or Cancel."
    elif target_selection_mode == TARGET_SELECTION_MODE_EFFECT:
        target_selection_label.text = "Select a valid target for this effect, or Cancel to undo activation."
    else:
        target_selection_label.text = "Select a target."

    if target_selection_cancel_button != null:
        target_selection_cancel_button.disabled = false

func _refresh_chain_panel_ui() -> void:
    if chain_panel == null:
        return

    if chain_status_label != null:
        if chain_in_progress:
            chain_status_label.text = "Chain: %d link(s)" % chain_links.size()
        else:
            chain_status_label.text = "Chain: Idle"

    var player_response_open: bool = false
    var enemy_response_open: bool = false
    if chain_in_progress and not player_state.is_empty() and not enemy_state.is_empty():
        if chain_response_window_owner == OWNER_PLAYER:
            player_response_open = _has_available_response_for_owner(OWNER_PLAYER)
        elif chain_response_window_owner == OWNER_ENEMY:
            enemy_response_open = _has_available_response_for_owner(OWNER_ENEMY)

    if chain_response_label != null:
        if player_response_open:
            chain_response_label.text = "Response window: Activate a set Spell/Trap, or Pass."
        elif enemy_response_open and debug_manual_enemy_chain_responses:
            chain_response_label.text = "Enemy response window open (debug manual mode). Click enemy set cards or force pass."
        elif chain_in_progress:
            chain_response_label.text = "Waiting for chain responses..."
        else:
            chain_response_label.text = ""

    if chain_debug_label != null:
        var owner_text: String = "-"
        if chain_in_progress:
            owner_text = "You" if chain_response_window_owner == OWNER_PLAYER else "Enemy"
        chain_debug_label.text = "Debug Enemy Manual: %s | Response Owner: %s | Pass Count: %d" % [str(debug_manual_enemy_chain_responses), owner_text, chain_pass_count]

    if chain_pass_button != null:
        chain_pass_button.visible = player_response_open
        chain_pass_button.disabled = not player_response_open

    if chain_enemy_pass_button != null:
        var show_enemy_pass: bool = chain_in_progress and debug_manual_enemy_chain_responses and chain_response_window_owner == OWNER_ENEMY
        chain_enemy_pass_button.visible = show_enemy_pass
        chain_enemy_pass_button.disabled = not show_enemy_pass

    if chain_history_label != null:
        chain_history_label.text = "\n".join(chain_history_lines)

    _refresh_chain_stack_ui()
    _refresh_chain_reactive_card_feedback()

    var player_window_is_open: bool = chain_in_progress and chain_response_window_owner == OWNER_PLAYER
    emit_signal("chain_response_window_changed", OWNER_PLAYER, player_window_is_open, player_response_open)
    var enemy_window_is_open: bool = chain_in_progress and chain_response_window_owner == OWNER_ENEMY
    emit_signal("chain_response_window_changed", OWNER_ENEMY, enemy_window_is_open, enemy_response_open)

func _refresh_chain_stack_ui() -> void:
    if chain_stack_vbox == null:
        return

    var current_link_count: int = chain_links.size()
    var existing_children: Array[Node] = []
    var child_count: int = chain_stack_vbox.get_child_count()
    for child_index: int in range(child_count):
        var child_node: Node = chain_stack_vbox.get_child(child_index)
        if child_node != null:
            existing_children.append(child_node)

    for child_node: Node in existing_children:
        child_node.queue_free()

    if chain_links.is_empty():
        var idle_label: Label = Label.new()
        idle_label.text = "No active links"
        chain_stack_vbox.add_child(idle_label)
    else:
        var newest_link_number: int = chain_links.size()
        var display_row_index: int = 0

        for reverse_index: int in range(chain_links.size() - 1, -1, -1):
            var link: Dictionary = chain_links[reverse_index] as Dictionary
            var link_owner: int = int(link.get("owner", OWNER_PLAYER))
            var owner_text: String = "You" if link_owner == OWNER_PLAYER else "Enemy"
            var link_number: int = reverse_index + 1
            var speed: int = int(link.get("speed", 1))

            var row_panel: PanelContainer = PanelContainer.new()
            row_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
            chain_stack_vbox.add_child(row_panel)

            var row_style: StyleBoxFlat = StyleBoxFlat.new()
            row_style.corner_radius_top_left = 4
            row_style.corner_radius_top_right = 4
            row_style.corner_radius_bottom_left = 4
            row_style.corner_radius_bottom_right = 4
            row_style.content_margin_left = 4.0
            row_style.content_margin_top = 2.0
            row_style.content_margin_right = 4.0
            row_style.content_margin_bottom = 2.0

            var is_focus_row: bool = chain_in_progress and link_number == newest_link_number
            if is_focus_row:
                row_style.bg_color = Color(0.2, 0.28, 0.38, 0.9)
                row_style.border_width_left = 2
                row_style.border_width_top = 2
                row_style.border_width_right = 2
                row_style.border_width_bottom = 2
                row_style.border_color = Color(0.65, 0.85, 1.0, 0.95)
            else:
                var stripe_alpha: float = 0.22 if display_row_index % 2 == 0 else 0.14
                row_style.bg_color = Color(0.14, 0.14, 0.14, stripe_alpha)
            row_panel.add_theme_stylebox_override("panel", row_style)

            var row: HBoxContainer = HBoxContainer.new()
            row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
            row_panel.add_child(row)

            var speed_badge: Label = Label.new()
            speed_badge.custom_minimum_size = Vector2(30.0, 20.0)
            speed_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
            speed_badge.text = "S%d" % speed
            speed_badge.modulate = _get_chain_speed_badge_color(speed)
            row.add_child(speed_badge)

            var row_text: String = "CL%d | %s | This card" % [link_number, owner_text]
            if is_focus_row:
                row_text += "  < Respond to this"

            var text_label: Label = Label.new()
            text_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
            text_label.text = row_text
            row.add_child(text_label)

            row_panel.modulate = Color(1.0, 1.0, 1.0, 0.0)
            row_panel.position = Vector2(16.0, 0.0)
            var row_tween: Tween = create_tween()
            row_tween.set_parallel(true)
            row_tween.tween_property(row_panel, "modulate:a", 1.0, 0.14).set_delay(float(display_row_index) * 0.02)
            row_tween.tween_property(row_panel, "position:x", 0.0, 0.14).set_delay(float(display_row_index) * 0.02)

            display_row_index += 1

    if last_rendered_chain_link_count >= 0 and current_link_count != last_rendered_chain_link_count:
        _play_chain_stack_pulse_animation(current_link_count > last_rendered_chain_link_count)
    last_rendered_chain_link_count = current_link_count

func _get_chain_speed_badge_color(speed: int) -> Color:
    if speed >= 3:
        return Color(1.0, 0.62, 0.62, 1.0)
    if speed == 2:
        return Color(0.95, 0.86, 0.5, 1.0)
    return Color(0.62, 0.86, 1.0, 1.0)

func _play_chain_stack_pulse_animation(is_growing: bool) -> void:
    if chain_stack_scroll == null:
        return

    if chain_stack_pulse_tween != null and chain_stack_pulse_tween.is_valid():
        chain_stack_pulse_tween.kill()

    var pulse_color: Color = Color(0.72, 0.92, 1.0, 1.0)
    if not is_growing:
        pulse_color = Color(1.0, 0.86, 0.74, 1.0)

    chain_stack_scroll.modulate = Color(1.0, 1.0, 1.0, 1.0)
    chain_stack_pulse_tween = create_tween()
    chain_stack_pulse_tween.tween_property(chain_stack_scroll, "modulate", pulse_color, 0.08)
    chain_stack_pulse_tween.tween_property(chain_stack_scroll, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.16)

func _load_card_preview_texture(card_instance: CardInstance) -> Texture2D:
    if card_instance == null:
        return null

    var image_path: String = str(card_instance.card_data.get("image_path", ""))
    if image_path.is_empty():
        return null

    var loaded_resource: Resource = load(image_path)
    if loaded_resource is Texture2D:
        return loaded_resource as Texture2D

    return null

func _refresh_chain_reactive_card_feedback() -> void:
    if target_selection_active:
        _apply_target_selection_card_interaction()
        return

    var stale_ui_ids: Array[int] = []

    for key_variant: Variant in card_instances_by_ui_id.keys():
        var ui_id: int = int(key_variant)
        var ui_object: Object = instance_from_id(ui_id)
        var card_ui: CardUI = ui_object as CardUI
        if card_ui == null:
            stale_ui_ids.append(ui_id)
            continue

        var card_instance: CardInstance = card_instances_by_ui_id[ui_id] as CardInstance
        if card_instance == null:
            _set_card_ui_target_selection_state(card_ui, false, false)
            _set_card_ui_chain_reactive_highlight(card_ui, false)
            card_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
            continue

        _set_card_ui_target_selection_state(card_ui, false, false)

        var can_chain_respond: bool = _can_card_respond_in_current_chain_window(card_instance)
        _set_card_ui_chain_reactive_highlight(card_ui, can_chain_respond)

        if chain_in_progress:
            if can_chain_respond:
                card_ui.mouse_filter = Control.MOUSE_FILTER_STOP
            else:
                card_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
        else:
            if card_instance.owner == OWNER_PLAYER:
                card_ui.mouse_filter = Control.MOUSE_FILTER_STOP
            elif debug_manual_enemy_chain_responses and chain_response_window_owner == OWNER_ENEMY and chain_in_progress:
                card_ui.mouse_filter = Control.MOUSE_FILTER_STOP
            else:
                card_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE

    for stale_ui_id: int in stale_ui_ids:
        card_instances_by_ui_id.erase(stale_ui_id)

func _can_card_respond_in_current_chain_window(card_instance: CardInstance) -> bool:
    if card_instance == null:
        return false
    if not chain_in_progress:
        return false
    if card_instance.owner != chain_response_window_owner:
        return false

    var response_actions: Array[StringName] = get_available_actions_for_card(card_instance)
    return response_actions.has(ACTION_ACTIVATE_SET_SPELL_TRAP)

func _set_card_ui_chain_reactive_highlight(card_ui: CardUI, is_enabled: bool) -> void:
    if card_ui == null:
        return

    if card_ui.has_method("set_chain_reactive_highlight"):
        card_ui.call("set_chain_reactive_highlight", is_enabled)
        return

    if is_enabled:
        card_ui.modulate = Color(1.0, 1.0, 0.78, 1.0)
    else:
        card_ui.modulate = Color(1.0, 1.0, 1.0, 1.0)

func _set_enemy_card_interaction_enabled(enabled: bool) -> void:
    for zone_value: Variant in enemy_zones.values():
        var zone_node: Control = zone_value as Control
        if zone_node == null:
            continue

        var child_count: int = zone_node.get_child_count()
        for child_index: int in range(child_count):
            var enemy_card_ui: CardUI = zone_node.get_child(child_index) as CardUI
            if enemy_card_ui == null:
                continue
            enemy_card_ui.mouse_filter = Control.MOUSE_FILTER_STOP if enabled else Control.MOUSE_FILTER_IGNORE

func _on_chain_pass_button_pressed() -> void:
    pass_chain_response_for_player()

func _on_chain_enemy_pass_button_pressed() -> void:
    pass_chain_response_for_enemy_debug()

func _on_chain_state_changed_for_ui(_link_count: int, _resolving: bool) -> void:
    _refresh_chain_panel_ui()
    _refresh_phase_display()

func _on_chain_activate_for_ui(card_instance: RefCounted, action: StringName) -> void:
    if not _is_chain_activation_action(action):
        return

    var owner_text: String = "You"
    if card_instance != null and int(card_instance.owner) == OWNER_ENEMY:
        owner_text = "Enemy"

    var link_number: int = 1
    if chain_in_progress:
        link_number = maxi(1, chain_links.size())

    _push_chain_history_line("CL%d %s activated this card" % [link_number, owner_text])

func _on_chain_resolve_for_ui(_card_instance: RefCounted, action: StringName, success: bool) -> void:
    if not _is_chain_activation_action(action):
        return

    if chain_in_progress:
        return

    var result_text: String = "resolved" if success else "no effect"
    _push_chain_history_line("Resolve this card -> %s" % [result_text])

func _play_chain_resolve_flash(owner_id: int) -> void:
    if chain_vfx_overlay == null:
        return

    var flash_color: Color = Color(0.4, 0.72, 1.0, 0.0)
    if owner_id == OWNER_ENEMY:
        flash_color = Color(1.0, 0.48, 0.35, 0.0)

    chain_vfx_overlay.color = flash_color

    var tween: Tween = create_tween()
    tween.set_trans(Tween.TRANS_SINE)
    tween.set_ease(Tween.EASE_OUT)
    tween.tween_property(chain_vfx_overlay, "color:a", chain_resolve_flash_alpha, 0.05)
    tween.tween_property(chain_vfx_overlay, "color:a", 0.0, chain_resolve_flash_duration)

func _push_chain_history_line(history_line: String) -> void:
    chain_history_lines.append(history_line)
    while chain_history_lines.size() > CHAIN_HISTORY_MAX_LINES:
        chain_history_lines.pop_front()

    _refresh_chain_panel_ui()

func _is_chain_activation_action(action: StringName) -> bool:
    return action == ACTION_ACTIVATE_SPELL or action == ACTION_ACTIVATE_SET_SPELL_TRAP

func _normalize_state_arrays(state: Dictionary) -> void:
    if state.is_empty():
        return

    if not state.has(ZONE_KEY_MONSTER) or not (state[ZONE_KEY_MONSTER] is Array):
        state[ZONE_KEY_MONSTER] = []
    if not state.has(ZONE_KEY_SPELL_TRAP) or not (state[ZONE_KEY_SPELL_TRAP] is Array):
        state[ZONE_KEY_SPELL_TRAP] = []

    var monster_slots: Array = state[ZONE_KEY_MONSTER] as Array
    var spell_slots: Array = state[ZONE_KEY_SPELL_TRAP] as Array

    while monster_slots.size() < PLAYER_MONSTER_ZONE_COUNT:
        monster_slots.append(null)
    while spell_slots.size() < PLAYER_SPELL_ZONE_COUNT:
        spell_slots.append(null)

    while monster_slots.size() > PLAYER_MONSTER_ZONE_COUNT:
        monster_slots.pop_back()
    while spell_slots.size() > PLAYER_SPELL_ZONE_COUNT:
        spell_slots.pop_back()

func _correct_zone_membership_for_owner(state: Dictionary, owner_id: int) -> void:
    var owner_hand: Array = state[ZONE_KEY_HAND] as Array
    var owner_deck: Array = state[ZONE_KEY_DECK] as Array
    var owner_gy: Array = state[ZONE_KEY_GRAVEYARD] as Array
    var owner_banished: Array = state[ZONE_KEY_BANISHED] as Array
    var owner_extra: Array = state[ZONE_KEY_EXTRA] as Array
    var owner_monster_slots: Array = state[ZONE_KEY_MONSTER] as Array
    var owner_spell_slots: Array = state[ZONE_KEY_SPELL_TRAP] as Array

    for hand_item: Variant in owner_hand:
        var hand_card: RefCounted = hand_item as RefCounted
        if hand_card != null:
            hand_card.owner = owner_id
            hand_card.set_zone(CARD_ZONE_HAND)

    for deck_item: Variant in owner_deck:
        var deck_card: RefCounted = deck_item as RefCounted
        if deck_card != null:
            deck_card.owner = owner_id
            deck_card.set_zone(CARD_ZONE_DECK)

    for gy_item: Variant in owner_gy:
        var gy_card: RefCounted = gy_item as RefCounted
        if gy_card != null:
            gy_card.owner = owner_id
            gy_card.set_zone(CARD_ZONE_GRAVEYARD)

    for banished_item: Variant in owner_banished:
        var banished_card: RefCounted = banished_item as RefCounted
        if banished_card != null:
            banished_card.owner = owner_id
            banished_card.set_zone(CARD_ZONE_BANISHED)

    for extra_item: Variant in owner_extra:
        var extra_card: RefCounted = extra_item as RefCounted
        if extra_card != null:
            extra_card.owner = owner_id
            extra_card.set_zone(CARD_ZONE_EXTRA)

    for slot_index: int in range(owner_monster_slots.size()):
        var monster: RefCounted = owner_monster_slots[slot_index] as RefCounted
        if monster == null:
            continue
        monster.owner = owner_id
        monster.set_zone(CARD_ZONE_MONSTER, slot_index)

        if not monster.is_monster():
            owner_monster_slots[slot_index] = null
            send_to_grave(null, monster, &"illegal_zone_state")

    for slot_index: int in range(owner_spell_slots.size()):
        var spell_trap: RefCounted = owner_spell_slots[slot_index] as RefCounted
        if spell_trap == null:
            continue
        spell_trap.owner = owner_id
        spell_trap.set_zone(CARD_ZONE_SPELL_TRAP, slot_index)

        if spell_trap.is_monster():
            owner_spell_slots[slot_index] = null
            send_to_grave(null, spell_trap, &"illegal_zone_state")

func _end_duel(winner: int, reason: StringName) -> void:
    if duel_has_ended:
        return

    duel_has_ended = true
    enemy_turn_in_progress = false
    chain_in_progress = false
    chain_links.clear()
    chain_pass_count = 0
    _clear_target_selection_mode()
    _refresh_chain_panel_ui()
    winner_owner = winner
    duel_end_reason = reason
    _refresh_life_point_display()
    _refresh_phase_display()
    emit_signal("duel_ended", winner_owner, duel_end_reason)

func resolve_battle_for_attacker(card_ui: CardUI, attacker: RefCounted, selected_defender: CardInstance = null) -> bool:
    if duel_has_ended:
        return false
    if attacker == null:
        return false

    var attacker_owner: int = int(attacker.owner)
    var opponent_owner: int = OWNER_ENEMY if attacker_owner == OWNER_PLAYER else OWNER_PLAYER
    var opponent_state: Dictionary = _get_state_by_owner(opponent_owner)
    var defender: CardInstance = selected_defender
    if defender != null:
        var defender_still_valid: bool = defender.current_zone == CARD_ZONE_MONSTER and int(defender.owner) == opponent_owner
        if not defender_still_valid:
            defender = null
    if defender == null:
        defender = _get_first_attack_target(opponent_state) as CardInstance

    var battle_context: Dictionary = _build_action_context(attacker_owner)
    battle_context[RuleEngine.CONTEXT_CURRENT_PHASE] = PHASE_BATTLE
    battle_context[RuleEngine.CONTEXT_OPPONENT_HAS_MONSTERS] = _has_any_monster(opponent_state)
    battle_context[RuleEngine.CONTEXT_HAS_ATTACK_TARGET] = defender != null

    if not rule_engine.can_declare_attack(attacker, battle_context):
        return false

    var attacker_atk: int = _get_attack_value(attacker)
    if defender == null:
        _apply_life_point_damage(opponent_owner, attacker_atk)
        attacker.has_attacked_this_turn = true
        sync_card_ui_from_instance(card_ui, attacker)
        return true

    if int(defender.battle_position) == BATTLE_POSITION_DEFENSE:
        var defender_def: int = _get_defense_value(defender)
        if attacker_atk > defender_def:
            action_resolver.destroy_card(null, defender, self, &"battle")
        elif attacker_atk < defender_def:
            _apply_life_point_damage(attacker_owner, defender_def - attacker_atk)
    else:
        var defender_atk: int = _get_attack_value(defender)
        if attacker_atk > defender_atk:
            _apply_life_point_damage(opponent_owner, attacker_atk - defender_atk)
            action_resolver.destroy_card(null, defender, self, &"battle")
        elif attacker_atk < defender_atk:
            _apply_life_point_damage(attacker_owner, defender_atk - attacker_atk)
            action_resolver.destroy_card(card_ui, attacker, self, &"battle")
        else:
            action_resolver.destroy_card(card_ui, attacker, self, &"battle")
            action_resolver.destroy_card(null, defender, self, &"battle")

    attacker.has_attacked_this_turn = true
    sync_card_ui_from_instance(card_ui, attacker)
    return true

func get_first_free_slot(owner_id: int, target_zone: int) -> int:
    var owner_state: Dictionary = _get_state_by_owner(owner_id)

    if target_zone == CARD_ZONE_MONSTER:
        return _first_free_slot(owner_state[ZONE_KEY_MONSTER] as Array)
    if target_zone == CARD_ZONE_SPELL_TRAP:
        return _first_free_slot(owner_state[ZONE_KEY_SPELL_TRAP] as Array)

    return -1

func move_card_to_zone(card_ui: CardUI, card_instance: RefCounted, target_zone: int, slot_index: int = -1) -> bool:
    if card_instance == null:
        return false
    if duel_has_ended:
        return false

    var owner_state: Dictionary = _get_state_by_owner(card_instance.owner)

    if target_zone == CARD_ZONE_MONSTER:
        var monster_slots_validate: Array = owner_state[ZONE_KEY_MONSTER] as Array
        if slot_index < 0 or slot_index >= monster_slots_validate.size() or monster_slots_validate[slot_index] != null:
            return false
    elif target_zone == CARD_ZONE_SPELL_TRAP:
        var spell_slots_validate: Array = owner_state[ZONE_KEY_SPELL_TRAP] as Array
        if slot_index < 0 or slot_index >= spell_slots_validate.size() or spell_slots_validate[slot_index] != null:
            return false
    elif target_zone != CARD_ZONE_HAND and target_zone != CARD_ZONE_GRAVEYARD and target_zone != CARD_ZONE_BANISHED and target_zone != CARD_ZONE_EXTRA:
        return false

    _remove_card_from_current_zone(owner_state, card_instance)

    if target_zone == CARD_ZONE_HAND:
        var hand_cards: Array = owner_state[ZONE_KEY_HAND] as Array
        hand_cards.append(card_instance)
        slot_index = -1
    elif target_zone == CARD_ZONE_MONSTER:
        var monster_slots: Array = owner_state[ZONE_KEY_MONSTER] as Array
        monster_slots[slot_index] = card_instance
    elif target_zone == CARD_ZONE_SPELL_TRAP:
        var spell_slots: Array = owner_state[ZONE_KEY_SPELL_TRAP] as Array
        spell_slots[slot_index] = card_instance
    elif target_zone == CARD_ZONE_GRAVEYARD:
        var gy_cards: Array = owner_state[ZONE_KEY_GRAVEYARD] as Array
        gy_cards.append(card_instance)
        slot_index = -1
    elif target_zone == CARD_ZONE_BANISHED:
        var banished_cards: Array = owner_state[ZONE_KEY_BANISHED] as Array
        banished_cards.append(card_instance)
        slot_index = -1
    elif target_zone == CARD_ZONE_EXTRA:
        var extra_cards: Array = owner_state[ZONE_KEY_EXTRA] as Array
        extra_cards.append(card_instance)
        slot_index = -1

    card_instance.set_zone(target_zone, slot_index)

    var resolved_card_ui: CardUI = card_ui
    if resolved_card_ui == null:
        resolved_card_ui = _find_card_ui_for_instance(card_instance)

    if resolved_card_ui == null and card_instance.owner == OWNER_ENEMY:
        if target_zone == CARD_ZONE_MONSTER or target_zone == CARD_ZONE_SPELL_TRAP:
            resolved_card_ui = _spawn_card_ui_for_instance(card_instance)

    if resolved_card_ui != null:
        _move_card_ui_to_zone(resolved_card_ui, card_instance.owner, target_zone, slot_index)

    _run_state_based_checks()
    return true

func consume_normal_summon(owner_id: int) -> void:
    var owner_state: Dictionary = _get_state_by_owner(owner_id)
    var flags: Dictionary = owner_state[ZONE_KEY_FLAGS] as Dictionary
    flags["normal_summon_used"] = true

    if owner_id == _get_active_owner():
        turn_manager.use_normal_summon()

func sync_card_ui_from_instance(card_ui: CardUI, card_instance: RefCounted) -> void:
    if card_ui == null or card_instance == null:
        return
    _sync_card_ui_from_instance(card_ui, card_instance)

func _remove_card_from_current_zone(state: Dictionary, card_instance: RefCounted) -> void:
    if card_instance.current_zone == CARD_ZONE_DECK:
        var deck_cards: Array = state[ZONE_KEY_DECK] as Array
        deck_cards.erase(card_instance)
        return

    if card_instance.current_zone == CARD_ZONE_HAND:
        var hand_cards: Array = state[ZONE_KEY_HAND] as Array
        hand_cards.erase(card_instance)
        return

    if card_instance.current_zone == CARD_ZONE_MONSTER:
        var monster_slots: Array = state[ZONE_KEY_MONSTER] as Array
        if card_instance.zone_slot_index >= 0 and card_instance.zone_slot_index < monster_slots.size():
            monster_slots[card_instance.zone_slot_index] = null
        return

    if card_instance.current_zone == CARD_ZONE_SPELL_TRAP:
        var spell_slots: Array = state[ZONE_KEY_SPELL_TRAP] as Array
        if card_instance.zone_slot_index >= 0 and card_instance.zone_slot_index < spell_slots.size():
            spell_slots[card_instance.zone_slot_index] = null
        return

    if card_instance.current_zone == CARD_ZONE_GRAVEYARD:
        var gy_cards: Array = state[ZONE_KEY_GRAVEYARD] as Array
        gy_cards.erase(card_instance)
        return

    if card_instance.current_zone == CARD_ZONE_BANISHED:
        var banished_cards: Array = state[ZONE_KEY_BANISHED] as Array
        banished_cards.erase(card_instance)
        return

    if card_instance.current_zone == CARD_ZONE_EXTRA:
        var extra_cards: Array = state[ZONE_KEY_EXTRA] as Array
        extra_cards.erase(card_instance)

func _move_card_ui_to_zone(card_ui: CardUI, owner_id: int, target_zone: int, slot_index: int) -> void:
    var target_zone_node: Control = _get_zone_node_for(owner_id, target_zone, slot_index)
    if target_zone_node == null:
        var ui_instance_id: int = card_ui.get_instance_id()
        if card_instances_by_ui_id.has(ui_instance_id):
            card_instances_by_ui_id.erase(ui_instance_id)
        card_ui.queue_free()
        return

    var previous_parent: Node = card_ui.get_parent()
    if previous_parent != null:
        previous_parent.remove_child(card_ui)

    target_zone_node.add_child(card_ui)
    _apply_card_layout_for_zone(card_ui, target_zone_node)

    if target_zone == CARD_ZONE_HAND and owner_id == OWNER_PLAYER:
        _layout_player_hand()

func _apply_card_layout_for_zone(card_ui: CardUI, zone_node: Control) -> void:
    if card_ui == null or zone_node == null:
        return

    var target_size: Vector2 = _get_zone_card_size(zone_node)
    var effective_target_size: Vector2 = _get_effective_card_size(target_size)
    var target_scale: Vector2 = _get_zone_card_scale(zone_node)
    var target_offset: Vector2 = _get_zone_card_offset(zone_node)

    card_ui.apply_display_size(effective_target_size)
    card_ui.scale = target_scale
    card_ui.position = target_offset

func _get_zone_card_size(zone_node: Control) -> Vector2:
    if zone_node == null:
        return DEFAULT_ZONE_CARD_SIZE

    if zone_node.has_method("get_card_size"):
        var custom_size_variant: Variant = zone_node.call("get_card_size", DEFAULT_ZONE_CARD_SIZE)
        if custom_size_variant is Vector2:
            return custom_size_variant as Vector2

    return DEFAULT_ZONE_CARD_SIZE

func _get_effective_card_size(base_size: Vector2) -> Vector2:
    return base_size + Vector2(global_card_size_offset_x, global_card_size_offset_y)

func _refresh_all_card_layouts() -> void:
    if zones.is_empty():
        return

    for zone_value: Variant in zones.values():
        var zone_node: Control = zone_value as Control
        if zone_node == null:
            continue

        var child_count: int = zone_node.get_child_count()
        for child_index: int in range(child_count):
            var card_ui: CardUI = zone_node.get_child(child_index) as CardUI
            if card_ui == null:
                continue
            _apply_card_layout_for_zone(card_ui, zone_node)

    _layout_player_hand()

func _get_zone_card_scale(zone_node: Control) -> Vector2:
    if zone_node == null:
        return Vector2.ONE

    if zone_node.has_method("get_card_scale"):
        var custom_scale_variant: Variant = zone_node.call("get_card_scale")
        if custom_scale_variant is Vector2:
            return custom_scale_variant as Vector2

    return Vector2.ONE

func _get_zone_card_offset(zone_node: Control) -> Vector2:
    if zone_node == null:
        return Vector2.ZERO

    if zone_node.has_method("get_card_offset"):
        var custom_offset_variant: Variant = zone_node.call("get_card_offset")
        if custom_offset_variant is Vector2:
            return custom_offset_variant as Vector2

    return Vector2.ZERO

func _get_zone_node_for(owner_id: int, zone: int, slot_index: int) -> Control:
    if owner_id == OWNER_PLAYER:
        return _get_player_zone_node_for(zone, slot_index)
    return _get_enemy_zone_node_for(zone, slot_index)

func _get_player_zone_node_for(zone: int, slot_index: int) -> Control:
    if zone == CARD_ZONE_HAND:
        return zones.get("PlayerHand") as Control
    if zone == CARD_ZONE_MONSTER:
        var monster_zone_name: String = "%s%d" % [PLAYER_MONSTER_ZONE_PREFIX, slot_index + 1]
        return zones.get(monster_zone_name) as Control
    if zone == CARD_ZONE_SPELL_TRAP:
        var spell_zone_name: String = "%s%d" % [PLAYER_SPELL_ZONE_PREFIX, slot_index + 1]
        return zones.get(spell_zone_name) as Control
    if zone == CARD_ZONE_GRAVEYARD:
        return zones.get("PlayerGY") as Control
    if zone == CARD_ZONE_BANISHED:
        return zones.get("PlayerBanished") as Control
    if zone == CARD_ZONE_EXTRA:
        return zones.get("PlayerExtra") as Control
    if zone == CARD_ZONE_DECK:
        return zones.get("PlayerDeck") as Control
    return null

func _get_enemy_zone_node_for(zone: int, slot_index: int) -> Control:
    if zone == CARD_ZONE_MONSTER:
        var monster_zone_name: String = "%s%d" % [ENEMY_MONSTER_ZONE_PREFIX, slot_index + 1]
        return zones.get(monster_zone_name) as Control
    if zone == CARD_ZONE_SPELL_TRAP:
        var spell_zone_name: String = "%s%d" % [ENEMY_SPELL_ZONE_PREFIX, slot_index + 1]
        return zones.get(spell_zone_name) as Control
    if zone == CARD_ZONE_GRAVEYARD:
        return zones.get("EnemyGY") as Control
    if zone == CARD_ZONE_BANISHED:
        return zones.get("EnemyBanished") as Control
    if zone == CARD_ZONE_EXTRA:
        return zones.get("EnemyExtra") as Control
    if zone == CARD_ZONE_DECK:
        return zones.get("EnemyDeck") as Control
    return null

func _sync_card_ui_from_instance(card_ui: CardUI, card_instance: RefCounted) -> void:
    if card_ui == null or card_instance == null:
        return

    card_ui.set_face_up(card_instance.face_up)

    if card_instance.battle_position == BATTLE_POSITION_ATTACK:
        card_ui.set_attack_position()
    else:
        card_ui.set_defense_position()

    card_ui.update_stats()
    _refresh_chain_reactive_card_feedback()

func _get_card_instance(card_ui: CardUI) -> RefCounted:
    if card_ui == null:
        return null

    var ui_id: int = card_ui.get_instance_id()
    if not card_instances_by_ui_id.has(ui_id):
        return null

    return card_instances_by_ui_id[ui_id] as RefCounted

func _find_card_ui_for_instance(card_instance: RefCounted) -> CardUI:
    if card_instance == null:
        return null

    var stale_ui_ids: Array[int] = []
    for key_variant: Variant in card_instances_by_ui_id.keys():
        var ui_id: int = int(key_variant)
        var mapped_instance: RefCounted = card_instances_by_ui_id[ui_id] as RefCounted
        if mapped_instance != card_instance:
            continue

        var ui_object: Object = instance_from_id(ui_id)
        var mapped_card_ui: CardUI = ui_object as CardUI
        if mapped_card_ui == null:
            stale_ui_ids.append(ui_id)
            continue

        return mapped_card_ui

    for stale_ui_id: int in stale_ui_ids:
        card_instances_by_ui_id.erase(stale_ui_id)

    return null

func _spawn_card_ui_for_instance(card_instance: RefCounted) -> CardUI:
    if card_instance == null:
        return null

    var card_ui: CardUI = CARD_UI_SCENE.instantiate() as CardUI
    if card_ui == null:
        return null

    card_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
    card_ui.set_card(card_instance.card_data)
    _sync_card_ui_from_instance(card_ui, card_instance)
    card_instances_by_ui_id[card_ui.get_instance_id()] = card_instance
    return card_ui

func _first_free_slot(slots: Array) -> int:
    for index: int in range(slots.size()):
        if slots[index] == null:
            return index
    return -1

func _has_free_monster_zone(state: Dictionary) -> bool:
    var monster_slots: Array = state[ZONE_KEY_MONSTER] as Array
    return _first_free_slot(monster_slots) >= 0

func _has_free_spell_zone(state: Dictionary) -> bool:
    var spell_slots: Array = state[ZONE_KEY_SPELL_TRAP] as Array
    return _first_free_slot(spell_slots) >= 0

func _has_any_monster(state: Dictionary) -> bool:
    var monster_slots: Array = state[ZONE_KEY_MONSTER] as Array
    for slot_item: Variant in monster_slots:
        if slot_item != null:
            return true
    return false

func _get_first_attack_target(state: Dictionary) -> RefCounted:
    var monster_slots: Array = state[ZONE_KEY_MONSTER] as Array
    for slot_item: Variant in monster_slots:
        if slot_item == null:
            continue
        var monster: RefCounted = slot_item as RefCounted
        if monster == null:
            continue
        return monster
    return null

func _get_attack_value(card_instance: RefCounted) -> int:
    if card_instance == null:
        return 0
    var data: Dictionary = card_instance.card_data as Dictionary
    return int(data.get("atk", 0))

func _get_defense_value(card_instance: RefCounted) -> int:
    if card_instance == null:
        return 0
    var data: Dictionary = card_instance.card_data as Dictionary
    return int(data.get("def", 0))

func _apply_life_point_damage(owner_id: int, amount: int) -> void:
    if duel_has_ended:
        return

    var clamped_amount: int = maxi(amount, 0)
    var state: Dictionary = _get_state_by_owner(owner_id)
    var current_lp: int = int(state.get(STATE_KEY_LIFE_POINTS, START_LIFE_POINTS))
    state[STATE_KEY_LIFE_POINTS] = maxi(0, current_lp - clamped_amount)
    _run_state_based_checks()

func _set_player_flag(flag_name: String, flag_value: bool) -> void:
    var flags: Dictionary = player_state[ZONE_KEY_FLAGS] as Dictionary
    flags[flag_name] = flag_value

func _reset_card_turn_flags_for_owner(owner_id: int) -> void:
    var state: Dictionary = _get_state_by_owner(owner_id)

    var hand_cards: Array = state[ZONE_KEY_HAND] as Array
    var deck_cards: Array = state[ZONE_KEY_DECK] as Array
    var gy_cards: Array = state[ZONE_KEY_GRAVEYARD] as Array
    var banished_cards: Array = state[ZONE_KEY_BANISHED] as Array
    var extra_cards: Array = state[ZONE_KEY_EXTRA] as Array
    var monster_slots: Array = state[ZONE_KEY_MONSTER] as Array
    var spell_slots: Array = state[ZONE_KEY_SPELL_TRAP] as Array

    _reset_card_array_turn_flags(hand_cards)
    _reset_card_array_turn_flags(deck_cards)
    _reset_card_array_turn_flags(gy_cards)
    _reset_card_array_turn_flags(banished_cards)
    _reset_card_array_turn_flags(extra_cards)
    _reset_card_array_turn_flags(monster_slots)
    _reset_card_array_turn_flags(spell_slots)

func _reset_card_array_turn_flags(card_array: Array) -> void:
    for item: Variant in card_array:
        if item == null:
            continue
        var card_instance: RefCounted = item as RefCounted
        if card_instance == null:
            continue
        card_instance.reset_turn_temporary_flags()
