extends RefCounted
class_name ActionResolver

func execute_action(action: StringName, card_ui: CardUI, card_instance: RefCounted, duel_manager: DuelManager) -> bool:
    if card_instance == null or duel_manager == null:
        return false

    duel_manager.notify_activate(card_instance, action)

    var success: bool = false
    if action == DuelManager.ACTION_NORMAL_SUMMON:
        success = _execute_normal_summon(card_ui, card_instance, duel_manager)
    elif action == DuelManager.ACTION_SET_MONSTER:
        success = _execute_set_monster(card_ui, card_instance, duel_manager)
    elif action == DuelManager.ACTION_ACTIVATE_SPELL:
        success = _execute_activate_spell(card_ui, card_instance, duel_manager)
    elif action == DuelManager.ACTION_ACTIVATE_SET_SPELL_TRAP:
        success = _execute_activate_set_spell_trap(card_ui, card_instance, duel_manager)
    elif action == DuelManager.ACTION_SET_SPELL:
        success = _execute_set_spell(card_ui, card_instance, duel_manager)
    elif action == DuelManager.ACTION_POS_CHANGE:
        success = _execute_position_change(card_ui, card_instance, duel_manager)
    elif action == DuelManager.ACTION_FLIP_SUMMON:
        success = _execute_flip_summon(card_ui, card_instance, duel_manager)
    elif action == DuelManager.ACTION_DECLARE_ATTACK:
        success = _execute_declare_attack(card_ui, card_instance, duel_manager)

    duel_manager.notify_resolve(card_instance, action, success)
    return success

func destroy_card(card_ui: CardUI, card_instance: RefCounted, duel_manager: DuelManager, reason: StringName = &"effect_destroy") -> bool:
    if card_instance == null or duel_manager == null:
        return false
    return duel_manager.destroy_card(card_ui, card_instance, reason)

func banish_card(card_ui: CardUI, card_instance: RefCounted, duel_manager: DuelManager, reason: StringName = &"effect_banish") -> bool:
    if card_instance == null or duel_manager == null:
        return false
    return duel_manager.banish_card(card_ui, card_instance, reason)

func _execute_normal_summon(card_ui: CardUI, card_instance: RefCounted, duel_manager: DuelManager) -> bool:
    var slot_index: int = duel_manager.get_first_free_slot(card_instance.owner, DuelManager.CARD_ZONE_MONSTER)
    if slot_index < 0:
        return false

    if not duel_manager.move_card_to_zone(card_ui, card_instance, DuelManager.CARD_ZONE_MONSTER, slot_index):
        return false

    card_instance.face_up = true
    card_instance.battle_position = DuelManager.BATTLE_POSITION_ATTACK
    card_instance.mark_normal_summoned()
    card_instance.has_changed_battle_position_this_turn = true

    duel_manager.consume_normal_summon(card_instance.owner)
    duel_manager.sync_card_ui_from_instance(card_ui, card_instance)
    return true

func _execute_set_monster(card_ui: CardUI, card_instance: RefCounted, duel_manager: DuelManager) -> bool:
    var slot_index: int = duel_manager.get_first_free_slot(card_instance.owner, DuelManager.CARD_ZONE_MONSTER)
    if slot_index < 0:
        return false

    if not duel_manager.move_card_to_zone(card_ui, card_instance, DuelManager.CARD_ZONE_MONSTER, slot_index):
        return false

    card_instance.face_up = false
    card_instance.battle_position = DuelManager.BATTLE_POSITION_DEFENSE
    card_instance.mark_normal_summoned()
    card_instance.has_changed_battle_position_this_turn = true

    duel_manager.consume_normal_summon(card_instance.owner)
    duel_manager.sync_card_ui_from_instance(card_ui, card_instance)
    return true

func _execute_activate_spell(card_ui: CardUI, card_instance: RefCounted, duel_manager: DuelManager) -> bool:
    return duel_manager.handle_spell_trap_activation(DuelManager.ACTION_ACTIVATE_SPELL, card_ui, card_instance)

func _execute_activate_set_spell_trap(card_ui: CardUI, card_instance: RefCounted, duel_manager: DuelManager) -> bool:
    return duel_manager.handle_spell_trap_activation(DuelManager.ACTION_ACTIVATE_SET_SPELL_TRAP, card_ui, card_instance)

func _execute_set_spell(card_ui: CardUI, card_instance: RefCounted, duel_manager: DuelManager) -> bool:
    var slot_index: int = duel_manager.get_first_free_slot(card_instance.owner, DuelManager.CARD_ZONE_SPELL_TRAP)
    if slot_index < 0:
        return false

    if not duel_manager.move_card_to_zone(card_ui, card_instance, DuelManager.CARD_ZONE_SPELL_TRAP, slot_index):
        return false

    card_instance.face_up = false
    card_instance.mark_set_this_turn()
    duel_manager.sync_card_ui_from_instance(card_ui, card_instance)
    return true

func _execute_position_change(card_ui: CardUI, card_instance: RefCounted, duel_manager: DuelManager) -> bool:
    card_instance.battle_position = DuelManager.BATTLE_POSITION_DEFENSE if card_instance.battle_position == DuelManager.BATTLE_POSITION_ATTACK else DuelManager.BATTLE_POSITION_ATTACK
    card_instance.has_changed_battle_position_this_turn = true
    duel_manager.sync_card_ui_from_instance(card_ui, card_instance)
    return true

func _execute_flip_summon(card_ui: CardUI, card_instance: RefCounted, duel_manager: DuelManager) -> bool:
    card_instance.face_up = true
    card_instance.battle_position = DuelManager.BATTLE_POSITION_ATTACK
    card_instance.mark_flip_summoned()
    card_instance.has_changed_battle_position_this_turn = true

    duel_manager.sync_card_ui_from_instance(card_ui, card_instance)
    return true

func _execute_declare_attack(card_ui: CardUI, card_instance: RefCounted, duel_manager: DuelManager) -> bool:
    return duel_manager.resolve_battle_for_attacker(card_ui, card_instance)
