extends Control
signal card_clicked(card_node)
signal card_hovered(card_node)
signal card_unhovered(card_node)

var card_id: String = ""
var hand_index: int = -1
var source: String = "hand"

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_STOP

func setup(card_data: Dictionary, new_hand_index: int = -1, new_source: String = "hand"):
    card_id = card_data.get("id", "")
    hand_index = new_hand_index
    source = new_source

    var image_path: String = card_data.get("image_path", "")
    if image_path != "" and ResourceLoader.exists(image_path):
        $TextureRect.texture = load(image_path)
    else:
        $TextureRect.texture = null

    if has_node("NameLabel"):
        $NameLabel.text = card_data.get("name", "")

func _on_mouse_entered():
    if source == "hand":
        card_hovered.emit(self)

func _on_mouse_exited():
    if source == "hand":
        card_unhovered.emit(self)
func _gui_input(event: InputEvent) -> void:
    if event is InputEventMouseButton:
        if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
            card_clicked.emit(self)
