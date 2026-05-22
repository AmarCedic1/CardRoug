extends Node2D

func setup(texture: Texture2D, render_config: Dictionary, is_defense: bool = false):
    $CardSprite.texture = texture
    $ShadowSprite.texture = texture

    if texture == null:
        return

    var tex_size: Vector2 = texture.get_size()
    if tex_size == Vector2.ZERO:
        return

    var zone_size: Vector2 = render_config.get("zone_size", Vector2(130, 130))
    var fit_ratio: float = float(render_config.get("fit_ratio", 0.8))

    var scale_x_mul: float = float(render_config.get("scale_x", 1.0))
    var scale_y_mul: float = float(render_config.get("scale_y", 0.9))
    var skew_deg: float = float(render_config.get("skew_deg", -12.0))
    var offset: Vector2 = render_config.get("offset", Vector2.ZERO)

    var defense_scale_x_mul: float = float(render_config.get("defense_scale_x", scale_x_mul))
    var defense_scale_y_mul: float = float(render_config.get("defense_scale_y", scale_y_mul))
    var defense_skew_deg: float = float(render_config.get("defense_skew_deg", skew_deg))
    var defense_rotation: float = float(render_config.get("defense_rotation", 90.0))
    var defense_offset: Vector2 = render_config.get("defense_offset", Vector2.ZERO)

    var shadow_offset: Vector2 = render_config.get("shadow_offset", Vector2(8, 10))
    var shadow_alpha: float = float(render_config.get("shadow_alpha", 0.25))

    var max_w: float = zone_size.x * fit_ratio
    var max_h: float = zone_size.y * fit_ratio
    var scale_factor: float = min(max_w / tex_size.x, max_h / tex_size.y)

    $ShadowSprite.modulate = Color(0, 0, 0, shadow_alpha)
    $ShadowSprite.position = shadow_offset

    if is_defense:
        scale = Vector2(scale_factor * defense_scale_x_mul, scale_factor * defense_scale_y_mul)
        skew = deg_to_rad(defense_skew_deg)
        rotation_degrees = defense_rotation
        position = zone_size / 2.0 + offset + defense_offset
    else:
        scale = Vector2(scale_factor * scale_x_mul, scale_factor * scale_y_mul)
        skew = deg_to_rad(skew_deg)
        rotation_degrees = 0
        position = zone_size / 2.0 + offset
