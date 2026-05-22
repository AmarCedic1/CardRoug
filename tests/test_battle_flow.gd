extends Node
class_name TestBattleFlow

func test_attack_vs_attack_destroys_defender_and_deals_damage() -> void:
    var duel_manager: DuelManager = _build_test_duel_manager()

    var attacker: CardInstance = _create_monster(2000, 1000, DuelManager.OWNER_PLAYER, DuelManager.CARD_ZONE_MONSTER, 0, DuelManager.BATTLE_POSITION_ATTACK)
    var defender: CardInstance = _create_monster(1500, 1200, DuelManager.OWNER_ENEMY, DuelManager.CARD_ZONE_MONSTER, 0, DuelManager.BATTLE_POSITION_ATTACK)

    var player_monsters: Array = duel_manager.player_state[DuelManager.ZONE_KEY_MONSTER] as Array
    var enemy_monsters: Array = duel_manager.enemy_state[DuelManager.ZONE_KEY_MONSTER] as Array
    player_monsters[0] = attacker
    enemy_monsters[0] = defender

    var success: bool = duel_manager.resolve_battle_for_attacker(null, attacker)

    assert(success, "Battle resolution should succeed for legal attack declaration.")
    assert(attacker.current_zone == DuelManager.CARD_ZONE_MONSTER, "Attacker should remain on field when stronger than defending attack monster.")
    assert(defender.current_zone == DuelManager.CARD_ZONE_GRAVEYARD, "Defender should be destroyed and sent to graveyard.")
    assert(duel_manager.get_life_points(DuelManager.OWNER_ENEMY) == 7500, "Enemy should take battle damage equal to ATK difference.")
    assert(attacker.has_attacked_this_turn, "Attacker must be marked as having attacked this turn.")

func test_attack_vs_attack_destroys_attacker_when_weaker() -> void:
    var duel_manager: DuelManager = _build_test_duel_manager()

    var attacker: CardInstance = _create_monster(1200, 1000, DuelManager.OWNER_PLAYER, DuelManager.CARD_ZONE_MONSTER, 0, DuelManager.BATTLE_POSITION_ATTACK)
    var defender: CardInstance = _create_monster(1800, 1200, DuelManager.OWNER_ENEMY, DuelManager.CARD_ZONE_MONSTER, 0, DuelManager.BATTLE_POSITION_ATTACK)

    var player_monsters: Array = duel_manager.player_state[DuelManager.ZONE_KEY_MONSTER] as Array
    var enemy_monsters: Array = duel_manager.enemy_state[DuelManager.ZONE_KEY_MONSTER] as Array
    player_monsters[0] = attacker
    enemy_monsters[0] = defender

    var success: bool = duel_manager.resolve_battle_for_attacker(null, attacker)

    assert(success, "Battle resolution should succeed for legal attack declaration.")
    assert(attacker.current_zone == DuelManager.CARD_ZONE_GRAVEYARD, "Weaker attacker should be destroyed and sent to graveyard.")
    assert(defender.current_zone == DuelManager.CARD_ZONE_MONSTER, "Stronger defender should remain on field.")
    assert(duel_manager.get_life_points(DuelManager.OWNER_PLAYER) == 7400, "Player should take battle damage equal to ATK difference.")

func test_direct_attack_deals_damage_when_no_defender() -> void:
    var duel_manager: DuelManager = _build_test_duel_manager()

    var attacker: CardInstance = _create_monster(1900, 1000, DuelManager.OWNER_PLAYER, DuelManager.CARD_ZONE_MONSTER, 0, DuelManager.BATTLE_POSITION_ATTACK)
    var player_monsters: Array = duel_manager.player_state[DuelManager.ZONE_KEY_MONSTER] as Array
    player_monsters[0] = attacker

    var success: bool = duel_manager.resolve_battle_for_attacker(null, attacker)

    assert(success, "Direct attack should resolve when opponent controls no monsters.")
    assert(duel_manager.get_life_points(DuelManager.OWNER_ENEMY) == 6100, "Enemy should lose LP equal to attacker's ATK on direct attack.")
    assert(attacker.current_zone == DuelManager.CARD_ZONE_MONSTER, "Direct attacker should remain on field.")

func test_second_attack_same_turn_is_blocked() -> void:
    var duel_manager: DuelManager = _build_test_duel_manager()

    var attacker: CardInstance = _create_monster(1600, 1000, DuelManager.OWNER_PLAYER, DuelManager.CARD_ZONE_MONSTER, 0, DuelManager.BATTLE_POSITION_ATTACK)
    var player_monsters: Array = duel_manager.player_state[DuelManager.ZONE_KEY_MONSTER] as Array
    player_monsters[0] = attacker

    var first_success: bool = duel_manager.resolve_battle_for_attacker(null, attacker)
    var second_success: bool = duel_manager.resolve_battle_for_attacker(null, attacker)

    assert(first_success, "First attack declaration should succeed.")
    assert(not second_success, "Monster must not be able to attack twice in one turn.")

func test_direct_attack_availability_reflects_opponent_board_state() -> void:
    var duel_manager: DuelManager = _build_test_duel_manager()

    var attacker: CardInstance = _create_monster(1700, 1000, DuelManager.OWNER_PLAYER, DuelManager.CARD_ZONE_MONSTER, 0, DuelManager.BATTLE_POSITION_ATTACK)
    var player_monsters: Array = duel_manager.player_state[DuelManager.ZONE_KEY_MONSTER] as Array
    player_monsters[0] = attacker

    var can_direct_without_defender: bool = duel_manager.is_direct_attack_available_for_instance(attacker)
    assert(can_direct_without_defender, "Direct attack should be available when opponent controls no monsters.")

    var defender: CardInstance = _create_monster(1000, 1000, DuelManager.OWNER_ENEMY, DuelManager.CARD_ZONE_MONSTER, 0, DuelManager.BATTLE_POSITION_ATTACK)
    var enemy_monsters: Array = duel_manager.enemy_state[DuelManager.ZONE_KEY_MONSTER] as Array
    enemy_monsters[0] = defender

    var can_direct_with_defender: bool = duel_manager.is_direct_attack_available_for_instance(attacker)
    assert(not can_direct_with_defender, "Direct attack should not be available when opponent controls at least one monster.")

func _build_test_duel_manager() -> DuelManager:
    var duel_manager: DuelManager = DuelManager.new()
    duel_manager.player_state = duel_manager._create_duelist_state(DuelManager.OWNER_PLAYER)
    duel_manager.enemy_state = duel_manager._create_duelist_state(DuelManager.OWNER_ENEMY)
    duel_manager.turn_manager = TurnManager.new()
    duel_manager.current_phase = DuelManager.PHASE_BATTLE
    duel_manager.is_player_turn = true
    return duel_manager

func _create_monster(atk: int, defense: int, owner_id: int, zone_id: int, slot_index: int, battle_position: int) -> CardInstance:
    var card_instance: CardInstance = CardInstance.new()
    var card_data: Dictionary = {
        "id": 3000,
        "name": "BattleTestMonster",
        "card_type": "monster",
        "atk": atk,
        "def": defense,
    }
    card_instance.setup(card_data, owner_id, zone_id, slot_index)
    card_instance.face_up = true
    card_instance.battle_position = battle_position
    return card_instance
