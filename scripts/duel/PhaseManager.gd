extends Node
class_name PhaseManager

const PHASE_DRAW: StringName = &"DRAW"
const PHASE_STANDBY: StringName = &"STANDBY"
const PHASE_MAIN_1: StringName = &"MAIN1"
const PHASE_BATTLE: StringName = &"BATTLE"
const PHASE_MAIN_2: StringName = &"MAIN2"
const PHASE_END: StringName = &"END"

const PHASE_ORDER: Array[StringName] = [
    PHASE_DRAW,
    PHASE_STANDBY,
    PHASE_MAIN_1,
    PHASE_BATTLE,
    PHASE_MAIN_2,
    PHASE_END,
]

var current_phase: StringName = PHASE_DRAW

func start_turn() -> void:
    current_phase = PHASE_DRAW

func next_phase() -> StringName:
    var current_index: int = PHASE_ORDER.find(current_phase)
    if current_index == -1:
        current_phase = PHASE_DRAW
        return current_phase

    if current_index >= PHASE_ORDER.size() - 1:
        current_phase = PHASE_END
        return current_phase

    current_phase = PHASE_ORDER[current_index + 1]
    return current_phase
