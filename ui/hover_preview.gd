extends Control
class_name HoverPreview

func show_card(card_data: Dictionary):
    visible = true

    $Artwork.texture = load(card_data["image_path"])
    $Name.text = card_data["name"]

    if card_data["card_type"] == "monster":
        $Stats.text = str(card_data["atk"]) + " / " + str(card_data["def"])
    else:
        $Stats.text = ""

    $Effect.text = card_data["effect_text"]

func hide_card():
    visible = false
