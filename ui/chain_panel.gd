extends PanelContainer
class_name ChainPanel

const MAX_HISTORY_LINES: int = 8

@onready var _status_label: Label = $VBox/StatusLabel as Label
@onready var _response_label: Label = $VBox/ResponseLabel as Label
@onready var _pass_button: Button = $VBox/PassButton as Button
@onready var _history_label: Label = $VBox/HistoryLabel as Label

var _duel_manager: DuelManager = null
var _history_lines: Array[String] = []

func _ready() -> void:
    _duel_manager = get_node_or_null("../DuelManager") as DuelManager
    if _duel_manager == null:
        push_warning("DuelManager not found for ChainPanel.")
        return

    _duel_manager.chain_state_changed.connect(_on_chain_state_changed)
    _duel_manager.chain_response_window_changed.connect(_on_chain_response_window_changed)
    _duel_manager.on_activate.connect(_on_activate)
    _duel_manager.on_resolve.connect(_on_resolve)
    _duel_manager.duel_ended.connect(_on_duel_ended)
    _pass_button.pressed.connect(_on_pass_button_pressed)

    _status_label.text = "Chain: Idle"
    _response_label.text = ""
    _pass_button.visible = false
    _pass_button.disabled = true
    _history_label.text = ""

func _on_chain_state_changed(link_count: int, resolving: bool) -> void:
    if link_count <= 0:
        _status_label.text = "Chain: Idle"
        if _duel_manager != null and not _duel_manager.chain_in_progress:
            _response_label.text = ""
        modulate = Color(1.0, 1.0, 1.0, 1.0)
        return

    if resolving:
        _status_label.text = "Resolving Chain (%d links)" % link_count
        modulate = Color(1.0, 0.95, 0.8, 1.0)
    else:
        _status_label.text = "Building Chain (%d links)" % link_count
        modulate = Color(0.82, 0.92, 1.0, 1.0)

func _on_chain_response_window_changed(owner_id: int, is_open: bool, can_respond: bool) -> void:
    if owner_id != DuelManager.OWNER_PLAYER:
        return

    var response_available: bool = is_open and can_respond
    _pass_button.visible = response_available
    _pass_button.disabled = not response_available

    if response_available:
        _response_label.text = "Response window: Activate a set Spell/Trap or press Pass."
    elif _duel_manager != null and _duel_manager.chain_in_progress:
        _response_label.text = "Waiting for next response..."
    else:
        _response_label.text = ""

func _on_activate(card_instance: RefCounted, action: StringName) -> void:
    if not _is_chain_activation_action(action):
        return

    var owner_text: String = "You"
    if card_instance != null and int(card_instance.owner) == DuelManager.OWNER_ENEMY:
        owner_text = "Enemy"

    var link_number: int = 1
    if _duel_manager != null and _duel_manager.chain_in_progress:
        link_number = maxi(1, _duel_manager.chain_links.size())

    _push_history_line("CL%d %s activated this card" % [link_number, owner_text])

func _on_resolve(card_instance: RefCounted, action: StringName, success: bool) -> void:
    if not _is_chain_activation_action(action):
        return

    var result_text: String = "resolved" if success else "no effect"
    _push_history_line("Resolve this card -> %s" % [result_text])

func _on_duel_ended(_winner: int, _reason: StringName) -> void:
    _pass_button.visible = false
    _pass_button.disabled = true
    _response_label.text = ""

func _on_pass_button_pressed() -> void:
    if _duel_manager == null:
        return
    _duel_manager.pass_chain_response_for_player()

func _is_chain_activation_action(action: StringName) -> bool:
    return action == DuelManager.ACTION_ACTIVATE_SPELL or action == DuelManager.ACTION_ACTIVATE_SET_SPELL_TRAP

func _push_history_line(line_text: String) -> void:
    _history_lines.append(line_text)
    while _history_lines.size() > MAX_HISTORY_LINES:
        _history_lines.pop_front()

    _history_label.text = "\n".join(_history_lines)
