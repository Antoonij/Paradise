/datum/element/devil_regeneration
	element_flags = ELEMENT_DETACH_ON_HOST_DESTROY|ELEMENT_BESPOKE
	id_arg_index = 2

	var/linked_timer    
	var/list/sounds = list('sound/magic/demon_consume.ogg', 'sound/effects/attackblob.ogg')    

/datum/element/devil_regeneration/Attach(datum/target)
    . = ..()
    var/mob/living/carbon/human/human = target

    if(!istype(human) && !human.mind?.has_antag_datum(/datum/antagonist/devil))
        return ELEMENT_INCOMPATIBLE

    RegisterSignal(human, COMSIG_CARBON_LOSE_ORGAN, PROC_REF(start_regen_bodypart))
    RegisterSignal(human, COMSIG_LIVING_DEATH, PROC_REF(on_death))

    var/obj/item/organ/internal/brain/brain = human.get_organ_slot(INTERNAL_ORGAN_BRAIN)
    brain?.decoy_brain = TRUE	

/datum/element/devil_regeneration/Detach(datum/target)
    . = ..()
    var/mob/living/carbon/human/human = target

    if(!istype(human))
        return

    UnregisterSignal(human, COMSIG_CARBON_LOSE_ORGAN)
    UnregisterSignal(human, COMSIG_LIVING_DEATH)

    var/obj/item/organ/internal/brain/brain = human.get_organ_slot(INTERNAL_ORGAN_BRAIN)
    brain?.decoy_brain = FALSE	

/datum/element/devil_regeneration/proc/start_regen_bodypart(datum/source, mob/living/carbon/human/human)
    SIGNAL_HANDLER

    var/obj/item/organ/external/external = source
    var/datum/antagonist/devil/devil = human?.mind?.has_antag_datum(/datum/antagonist/devil)

    if(!devil)
        return

    addtimer(CALLBACK(src, PROC_REF(regen_bodypart), human, external, devil), devil.regen_threshold)

/datum/element/devil_regeneration/proc/regen_bodypart(
    mob/living/carbon/human/human,
    obj/item/organ/external/external,
    datum/antagonist/devil/devil
    )
    external = new external.parent_organ_zone(human)
    human.heal_overall_damage(devil.regen_amount, devil.regen_amount)

    playsound(get_turf(human), pick(sounds), 50, 0, TRUE)
    update_status(human)

/datum/element/devil_regeneration/proc/on_death(datum/source, gibbed)
    SIGNAL_HANDLER

    if(gibbed) // You're not immortal anymore.
        return

    var/mob/living/carbon/human/human = source
    var/datum/antagonist/devil/devil = human?.mind?.has_antag_datum(/datum/antagonist/devil)

    if(!devil)
        return

    ADD_TRAIT(human, TRAIT_GODMODE, UNIQUE_TRAIT_SOURCE(src))
    to_chat(human, span_revenbignotice("Hellish powers are resurrecting you."))
    
    playsound(get_turf(human), 'sound/magic/vampire_anabiosis.ogg', 50, 0, TRUE)
    linked_timer = addtimer(CALLBACK(src, PROC_REF(regen_after_death), human, devil), devil.regen_threshold, TIMER_LOOP | TIMER_STOPPABLE)

/datum/element/devil_regeneration/proc/regen_after_death(mob/living/carbon/human/human, datum/antagonist/devil/devil)
    . = devil.check_banishment()
    switch(.)
        if(TRUE)
            REMOVE_TRAIT(human, TRAIT_GODMODE, UNIQUE_TRAIT_SOURCE(src))
            human.gib() // bye bye
        if(FALSE)
            apply_regeneration(human, devil)

/datum/element/devil_regeneration/proc/apply_regeneration(mob/living/carbon/human/human, datum/antagonist/devil/devil)
    if(human.health >= 100)
        REMOVE_TRAIT(human, TRAIT_GODMODE, UNIQUE_TRAIT_SOURCE(src))
        human.revive()
        deltimer(linked_timer)
        linked_timer = null

    human.heal_damages(
        devil.regen_amount, 
        devil.regen_amount,
        devil.regen_amount,
        devil.regen_amount,
        devil.regen_amount,
        devil.regen_amount,
        devil.regen_amount,
        devil.regen_amount,
        devil.regen_amount,
        TRUE,
        TRUE
        )

    human.check_and_regenerate_organs()
    playsound(get_turf(human), pick(sounds), 50, 0, TRUE)
    update_status(human)

/datum/element/devil_regeneration/proc/update_status(mob/living/carbon/human/human)
    human.update_body()
    human.updatehealth()	
    human.UpdateDamageIcon()
