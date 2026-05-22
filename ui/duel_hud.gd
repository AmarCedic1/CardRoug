extends Control
class_name DuelHud

@onready var _phase_label: Label = $PhaseLabel as Label
@onready var _next_phase_button: Button = $NextPhaseButton as Button
@onready var _duel_manager: DuelManager = get_node_or_null("../DuelManager") as DuelManager

func _ready() -> void:
    if _duel_manager == null:
        push_warning("DuelManager nicht gefunden für DuelHud.")
        return

    _duel_manager.phase_changed.connect(_on_phase_changed)
    _next_phase_button.pressed.connect(_on_next_phase_button_pressed)
    _refresh_ui(_duel_manager.get_current_phase(), _duel_manager.is_player_turn)

func _on_next_phase_button_pressed() -> void:
    if _duel_manager == null:
        return

    _duel_manager.on_next_phase_button_pressed()

func _on_phase_changed(phase: StringName, player_turn: bool) -> void:
    _refresh_ui(phase, player_turn)

func _refresh_ui(phase: StringName, player_turn: bool) -> void:
    var turn_text: String = "Dein Zug" if player_turn else "Gegnerzug"
    var phase_text: String = _get_phase_label_text(phase)
    _phase_label.text = "%s - Phase: %s" % [turn_text, phase_text]

    if player_turn:
        if phase == DuelManager.PHASE_END:
            _next_phase_button.text = "End Turn"
        else:
            _next_phase_button.text = "Next Phase"
    else:
        _next_phase_button.text = "Warte..."

    _next_phase_button.disabled = not player_turn

func _get_phase_label_text(phase: StringName) -> String:
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
