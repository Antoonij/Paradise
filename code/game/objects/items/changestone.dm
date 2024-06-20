/obj/item/changestone
	name = "An uncut ruby"
	desc = "The ruby shines and catches the light, despite being uncut."
	icon = 'icons/obj/artifacts.dmi'
	icon_state = "changerock"
	var/used = FALSE

/obj/item/changestone/attack_hand(mob/user)
	. = ..()
	morph_human(user, FALSE)

/obj/item/changestone/MouseDrop(atom/over_object, src_location, over_location, src_control, over_control, params)
	var/mob/user = usr
	attack_hand(user)
	return ..()

/obj/item/changestone/on_give(mob/living/carbon/giver, mob/living/carbon/receiver)
	. = ..()
	morph_human(receiver, FALSE)

/obj/item/changestone/proc/morph_human(mob/living/carbon/human/user, silent)
	. = FALSE
	if(!istype(user))
		if(!silent)
			to_chat(user, span_warning("You cannot handle with [src]."))
		return .

	if(used)
		if(!silent)
			to_chat(user, span_warning("[src] has already been used."))
		return .

	if(user.gloves)
		if(!silent)
			to_chat(user, span_warning("Your [user.gloves] have blocked [src] power."))
		return .

	if(user.change_gender(user.gender == FEMALE ? MALE : FEMALE))
		. = TRUE

	if(user.set_species(get_random_species()))
		. = TRUE
		to_chat(user, span_notice("You are now [user.dna.species]!"))
		update_appearance(UPDATE_DESC)

	if(.)
		to_chat(user, span_danger("The power of the [src] has affected you!"))
		used = .

/obj/item/changestone/update_desc(updates = ALL)
	. = ..()
	desc = "[initial(desc)][used ? " That one looks used." : null]"

