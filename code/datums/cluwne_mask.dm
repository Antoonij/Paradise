#define CLUWNE_PDA_SLIP_DAMAGE 10
#define CLUWNE_PDA_SLIP_GLOBALCOOLDOWN 10 (SECONDS)

#define CLUWNE_BIKEHORN_KNOCKDOWN_TIME 4 (SECONDS)
#define CLUWNE_BIKEHORN_GLOBALCOOLDOWN 6 (SECONDS)

#define CLUWNE_UNARMED_ATTACK_BLIND_TIME 2 (SECONDS)
#define CLUWNE_UNARMED_ATTACK_HALLUCINATION_TIME 30 (SECONDS)
#define CLUWNE_UNARMED_ATTACK_MAX_HALLUCINATION_TIME 90 (SECONDS)
#define CLUWNE_UNARMED_ATTACK_GLOBALCOOLDOWN 6 (SECONDS)

/datum/cluwne_mask
	/// Type of mob which we will transform into fake cluwne
	var/mob/living/carbon/human/cluwne
	/// Our cluwne pda. Used to receive heal when somebody slips on it and deal damage to victim.
	var/obj/item/pda/pda
	/// Linked bikehorn, we will use him to give various effects to target.
	var/obj/item/bikehorn/bikehorn
	/// Global cooldown of our actions. If true - your abilities won't work.
	DECLARE_COOLDOWN(global_cooldown)
	
/datum/cluwne_mask/proc/transform(mob/living/carbon/human/human)
	if(!istype(human))
		return
	if(!human.mind)
		return
	cluwne = human
	init_cluwne()
	
/datum/cluwne_mask/proc/init_cluwne(
	should_transform = TRUE,
	should_gain_effects = TRUE
)
	
	if(should_transform)
		transform_cluwne()
	if(should_gain_effects)
		init_cluwne_signals()
		init_pda_signals()
		init_bikehorn_signals()

/datum/cluwne_mask/proc/init_cluwne_signals()
	RegisterSignal(cluwne, COMSIG_HUMAN_EQUIPPED, PROC_REF(on_equip))
	RegisterSignal(cluwne, COMSIG_HUMAN_MELEE_UNARMED_ATTACK, PROC_REF(unarmed_attack))

/datum/cluwne_mask/proc/transform_cluwne()
	cluwne.mind.assigned_role = "Cluwne"
	cluwne.rename_character(newname = "cluwne")
	cluwne.drop_item_ground(cluwne.w_uniform, force = TRUE)
	cluwne.drop_item_ground(cluwne.shoes, force = TRUE)
	cluwne.drop_item_ground(cluwne.gloves, force = TRUE)
	cluwne.equip_to_slot_or_del(new /obj/item/clothing/under/cursedclown, ITEM_SLOT_CLOTH_INNER)
	cluwne.equip_to_slot_or_del(new /obj/item/clothing/gloves/cursedclown, ITEM_SLOT_GLOVES)
	cluwne.equip_to_slot_or_del(new /obj/item/clothing/shoes/cursedclown, ITEM_SLOT_FEET)
	cluwne.grant_mimicking()

/datum/cluwne_mask/proc/init_pda_signals()
	if(!pda)
		return
		
	RegisterSignal(pda, COMSIG_ITEM_QDELETED, PROC_REF(on_pda_delete))
	RegisterSignal(pda, COMSIG_COMPONENT_PARENT_SLIP, PROC_REF(on_pda_slip))
	
	if(!pda.GetComponent(/datum/component/slippery))
		pda.AddComponent(/datum/component/slippery)

/datum/cluwne_mask/proc/init_bikehorn_signals()
	if(!bikehorn)
		return
		
	RegisterSignal(bikehorn, COMSIG_ITEM_UNEQUIP, PROC_REF(bikehorn_unequip))
	RegisterSignal(bikehorn, COMSIG_ITEM_AFTERATTACK, PROC_REF(after_attack_bikehorn))

/datum/cluwne_mask/Destroy(force)
	cluwne.dust() // This is your new curse
	cluwne = null
	bikehorn = null
	pda = null
	
/datum/cluwne_mask/proc/on_equip(obj/item/item, slot, initial)
	SIGNAL_HANDLER
	
	switch(item.type)
		if(/obj/item/bikehorn)
			if(bikehorn)
				return
			if(slot != SLOT_HUD_LEFT_HAND || slot != SLOT_HUD_RIGHT_HAND)
				return
			bikehorn = item
			init_bikehorn_signals()
		if(/obj/item/pda)
			if(pda) // we link that only once.
				return
			pda = item
			init_pda_signals()

/datum/cluwne_mask/proc/unarmed_attack(mob/living/carbon/human/target, proximity)
	if(!COOLDOWN_FINISHED(src, global_cooldown))
		return
	if(!istype(target))
		return

	target.EyeBlind(CLUWNE_UNARMED_ATTACK_BLIND_TIME)
	target.AdjustHallucinate(CLUWNE_HALLUCINATION_TIME, bound_upper = CLUWNE_UNARMED_ATTACK_MAX_HALLUCINATION_TIME)
	send_honk(target)
	COOLDOWN_START(src, global_cooldown, CLUWNE_UNARMED_ATTACK_GLOBALCOOLDOWN)
	
/datum/cluwne_mask/proc/after_attack_bikehorn((obj/item/item, mob/living/carbon/human/target, mob/user, proximity, params)
	if(!COOLDOWN_FINISHED(src, global_cooldown))
		return
	if(!istype(target))
		return
		
	target.setKnockdown(CLUWNE_BIKEHORN_KNOCKDOWN_TIME)
	send_honk(target)
	COOLDOWN_START(src, global_cooldown, CLUWNE_BIKEHORN_GLOBALCOOLDOWN)
	
/datum/cluwne_mask/proc/on_pda_delete()
	UnregisterSignal(pda, COMSIG_ITEM_QDELETED)
	UnregisterSignal(pda, COMSIG_COMPONENT_PARENT_SLIP)
	pda = null
	
/// Signals was registered when you took bikehorn in hands slot, so we don't need extra checks
/datum/cluwne_mask/proc/bikehorn_unequip()
	UnregisterSignal(bikehorn, COMSIG_ITEM_UNEQUIP)
	UnregisterSignal(bikehorn, COMSIG_ITEM_AFTERATTACK)
	bikehorn = null

/datum/cluwne_mask/proc/on_pda_slip(mob/living/carbon/human/victim)	
	if(!COOLDOWN_FINISHED(src, global_cooldown))
		return
	if(victim != cluwne)
		var/applied_damage = CLUWNE_PDA_SLIP_DAMAGE + (victim.health / 10)
		victim.apply_damage(applied_damage, TOX)
		send_honk(victim)
	cluwne.heal_overall_damage(5, 5)
	COOLDOWN_START(src, global_cooldown, CLUWNE_PDA_SLIP_GLOBALCOOLDOWN)

/datum/cluwne_mask/proc/send_honk(mob/target)
	to_chat(target, "<font color='red' size='7'>HONK</font>")
	SEND_SOUND(target, sound('sound/items/airhorn.ogg'))

#undef CLUWNE_PDA_SLIP_DAMAGE
#undef CLUWNE_PDA_SLIP_GLOBALCOOLDOWN
#undef CLUWNE_BIKEHORN_KNOCKDOWN_TIME
#undef CLUWNE_BIKEHORN_GLOBALCOOLDOWN
#undef CLUWNE_UNARMED_ATTACK_BLIND_TIME
#undef CLUWNE_UNARMED_ATTACK_HALLUCINATION_TIME
#undef CLUWNE_UNARMED_ATTACK_MAX_HALLUCINATION_TIME
#undef CLUWNE_UNARMED_ATTACK_GLOBALCOOLDOWN
                                              
