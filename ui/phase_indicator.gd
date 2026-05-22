extends Label
class_name PhaseIndicator

@onready var _duel_manager: DuelManager = get_node_or_null("../DuelManager") as DuelManager

func _ready() -> void:
    if _duel_manager == null:
        push_warning("DuelManager nicht gefunden für PhaseIndicator.")
        return

    _duel_manager.phase_changed.connect(_on_phase_changed)
    _refresh_text(_duel_manager.get_current_phase(), _duel_manager.is_player_turn)

func _on_phase_changed(phase: StringName, player_turn: bool) -> void:
    _refresh_text(phase, player_turn)

func _refresh_text(phase: StringName, player_turn: bool) -> void:
    var turn_text: String = "Your Turn" if player_turn else "Enemy Turn"
    var phase_text: String = _phase_to_text(phase)
    text = "%s - %s" % [turn_text, phase_text]

func _phase_to_text(phase: StringName) -> String:
    if phase == DuelManager.PHASE_DRAW:
        return "Draw"
    if phase == DuelManager.PHASE_STANDBY:
        return "Standby"
    if phase == DuelManager.PHASE_MAIN_1:
        return "Main 1"
    if phase == DuelManager.PHASE_BATTLE:
        return "Battle"
    if phase == DuelManager.PHASE_MAIN_2:
        return "Main 2"
    if phase == DuelManager.PHASE_END:
        return "End"
    return str(phase)
