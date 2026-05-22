extends Node
class_name TurnManager

const OWNER_PLAYER: int = 0
const OWNER_ENEMY: int = 1

var turn_player: int = OWNER_PLAYER
var turn_count: int = 1
var normal_summon_used: bool = false

func start_duel(starting_owner: int = OWNER_PLAYER) -> void:
    turn_player = starting_owner
    turn_count = 1
    normal_summon_used = false

func next_turn() -> void:
    turn_player = OWNER_ENEMY if turn_player == OWNER_PLAYER else OWNER_PLAYER
    turn_count += 1
    normal_summon_used = false

func is_player_turn() -> bool:
    return turn_player == OWNER_PLAYER

func use_normal_summon() -> void:
    normal_summon_used = true

func reset_turn_flags() -> void:
    normal_summon_used = false

func can_normal_summon() -> bool:
    return not normal_summon_used
