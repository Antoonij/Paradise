#define TICKS_TO_MATURE 300
#define TICKS_TO_ADULT 420
#define TICKS_TO_ELDER 600
#define FLAG_PROCESS (1<<0) // processing datum
#define FLAG_HOST_REQUIRED (1<<1) // essential if we handle host
#define FLAG_HAS_HOST_EFFECT (1<<2) // if we applying something to host and want to transfer these effects between hosts. We'll need that in future.
/// processing flags
#define SHOULD_PROCESS_AFTER_DEATH (1<<0) // Doesn't register signals, process even borer is dead.

/datum/borer_datum
	var/mob/living/simple_animal/borer/user // our borer
	var/mob/living/carbon/human/host // our host
	var/mob/living/carbon/human/previous_host // previous host, used to del transferable effects from previous host.
	var/flags = NONE
	var/processing_flags = NONE

/datum/borer_datum/New(mob/living/simple_animal/borer/borer)
	if(!borer)
		qdel(src)
	Grant(borer)

/datum/borer_datum/proc/Grant(mob/living/simple_animal/borer/borer)
	user = borer
	host = borer.host
	if(QDELETED(user) || !on_apply())
		qdel(src)
		return FALSE
	if((flags & FLAG_HOST_REQUIRED) || (flags & FLAG_HAS_HOST_EFFECT)) // important to change host value.
		previous_host = borer.host
		RegisterSignal(user, COMSIG_BORER_ENTERED_HOST, PROC_REF(check_host))
		RegisterSignal(user, COMSIG_BORER_LEFT_HOST, PROC_REF(check_host)) 
	if((flags & FLAG_HAS_HOST_EFFECT) && (host)) 
		host_handle_buff()
	if(flags & FLAG_PROCESS)
		if(!(processing_flags & SHOULD_PROCESS_AFTER_DEATH))
			RegisterSignal(user, COMSIG_MOB_DEATH, PROC_REF(on_mob_death)) 
			RegisterSignal(user, COMSIG_LIVING_REVIVE, PROC_REF(on_mob_revive))
			if(user.stat != DEAD)
				START_PROCESSING(SSprocessing, src)
			return TRUE
		START_PROCESSING(SSprocessing, src)
	return TRUE

/datum/borer_datum/proc/check_host()
	SIGNAL_HANDLER
	host = user.host
	if(flags & FLAG_HAS_HOST_EFFECT)
		switch(host) 
			if(TRUE)
				host_handle_buff() // use host.
			if(FALSE)
				host_handle_buff(FALSE) // use previous_host to delete buff from previous host.
	previous_host = host

/datum/borer_datum/proc/host_handle_buff(var/grant = TRUE) // if we want transferable effects between hosts.
	return TRUE

/datum/borer_datum/Destroy(force)
	if((flags & FLAG_HOST_REQUIRED) || (flags & FLAG_HAS_HOST_EFFECT))
		UnregisterSignal(user, COMSIG_BORER_ENTERED_HOST)
		UnregisterSignal(user, COMSIG_BORER_LEFT_HOST)
	if((flags & FLAG_HAS_HOST_EFFECT) && (previous_host))
		host_handle_buff(FALSE)
	if(flags & FLAG_PROCESS)
		if(!(processing_flags & SHOULD_PROCESS_AFTER_DEATH))
			UnregisterSignal(user, COMSIG_MOB_DEATH)
			UnregisterSignal(user, COMSIG_LIVING_REVIVE)
		STOP_PROCESSING(SSprocessing, src)
	user = null
	host = null
	previous_host = null
	return ..()
	
/datum/borer_datum/proc/on_apply() // Apply something to BORER or untransferable effect to host.
	return TRUE

/datum/borer_datum/proc/on_mob_death()
	SIGNAL_HANDLER
	STOP_PROCESSING(SSprocessing, src)

/datum/borer_datum/proc/on_mob_revive()
	SIGNAL_HANDLER
	START_PROCESSING(SSprocessing, src)

/datum/borer_datum/borer_rank
	var/rankname = "Error"
	var/grow_time = 0 // how many time we need to gain new rank
	flags = FLAG_PROCESS
	
/datum/borer_datum/borer_rank/young
	rankname = "Young"
	grow_time = TICKS_TO_MATURE 

/datum/borer_datum/borer_rank/mature
	rankname = "Mature"
	grow_time = TICKS_TO_ADULT 

/datum/borer_datum/borer_rank/adult
	rankname = "Adult"
	grow_time = TICKS_TO_ELDER 
	flags = FLAG_PROCESS|FLAG_HOST_REQUIRED

/datum/borer_datum/borer_rank/elder
	rankname = "Elder"
	flags = FLAG_PROCESS|FLAG_HOST_REQUIRED

/datum/borer_datum/borer_rank/young/on_apply()
	user.update_transform(0.5)
	return TRUE

/datum/borer_datum/borer_rank/mature/on_apply()
	user.update_transform(2)
	user.maxHealth += 5
	return TRUE

/datum/borer_datum/borer_rank/adult/on_apply()
	user.maxHealth += 5
	return TRUE

/datum/borer_datum/borer_rank/elder/on_apply()
	user.maxHealth += 10
	return TRUE

/datum/borer_datum/borer_rank/young/process()
	user.adjustHealth(-0.1)

/datum/borer_datum/borer_rank/mature/process()
	user.adjustHealth(-0.15)

/datum/borer_datum/borer_rank/adult/process()
	user.adjustHealth(-0.2)
	if(host?.stat != DEAD && !user.sneaking)
		user.chemicals += 0.2

/datum/borer_datum/borer_rank/elder/process()
	user.adjustHealth(-0.3)
	if(host?.stat != DEAD)
		host.heal_overall_damage(0.4, 0.4)
		user.chemicals += 0.3

/datum/borer_chem
	var/chemname
	var/chemdesc = "This is a chemical"
	var/chemuse = 30
	var/quantity = 10

/datum/borer_chem/capulettium_plus
	chemname = "capulettium_plus"
	chemdesc = "Silences and masks pulse."

/datum/borer_chem/charcoal
	chemname = "charcoal"
	chemdesc = "Slowly heals toxin damage, also slowly removes other chemicals."

/datum/borer_chem/epinephrine
	chemname = "epinephrine"
	chemdesc = "Stabilizes critical condition and slowly heals suffocation damage."

/datum/borer_chem/fliptonium
	chemname = "fliptonium"
	chemdesc = "Causes uncontrollable flipping."
	chemuse = 50

/datum/borer_chem/hydrocodone
	chemname = "hydrocodone"
	chemdesc = "An extremely strong painkiller."

/datum/borer_chem/mannitol
	chemname = "mannitol"
	chemdesc = "Heals brain damage."

/datum/borer_chem/methamphetamine
	chemname = "methamphetamine"
	chemdesc = "Reduces stun times and increases stamina. Deals small amounts of brain damage."
	chemuse = 50

/datum/borer_chem/mitocholide
	chemname = "mitocholide"
	chemdesc = "Heals internal organ damage."

/datum/borer_chem/salbutamol
	chemname = "salbutamol"
	chemdesc = "Heals suffocation damage."

/datum/borer_chem/salglu_solution
	chemname = "salglu_solution"
	chemdesc = "Slowly heals brute and burn damage, also slowly restores blood."

/datum/borer_chem/spaceacillin
	chemname = "spaceacillin"
	chemdesc = "Slows progression of diseases and fights infections."

#undef TICKS_TO_MATURE
#undef TICKS_TO_ADULT
#undef TICKS_TO_ELDER
#undef FLAG_PROCESS
#undef FLAG_HOST_REQUIRED 
#undef FLAG_HAS_HOST_EFFECT 
#undef SHOULD_PROCESS_AFTER_DEATH
