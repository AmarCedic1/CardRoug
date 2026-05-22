extends Node
class_name GoatCarddatabase

var cards: Dictionary = {} # api_id(int) -> card dictionary

func _ready() -> void:
    load_goat_cards()
    print("GOAT cards loaded:", cards.size())
    print("First card:", cards.values()[0])

func load_goat_cards() -> void:
    var path: String = "res://data/goat_cards.json"
    var file: FileAccess = FileAccess.open(path, FileAccess.READ)
    if file == null:
        push_error("GOAT card file not found!")
        return

    var text: String = file.get_as_text()
    var data: Variant = JSON.parse_string(text)

    # data is a DICTIONARY of key->card
    if typeof(data) != TYPE_DICTIONARY:
        push_error("Invalid GOAT JSON structure")
        return

    # We convert internal_name -> card_data by api_id (as int keys)
    for key: Variant in data.keys():
        var card: Dictionary = data[key]
        if card.has("api_id"):
            var api_id: int = int(card["api_id"])
            cards[api_id] = card

func get_card_by_id(card_id: int) -> Variant:
    return cards.get(card_id)

func get_card_by_name(card_name: String) -> Variant:
    for card_id: Variant in cards:
        if cards[card_id]["name"] == card_name:
            return cards[card_id]
    return null
