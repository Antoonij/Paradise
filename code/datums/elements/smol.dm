/datum/element/smol
    element_flags = ELEMENT_DETACH_ON_HOST_DESTROY|ELEMENT_BESPOKE
	id_arg_index = 2

    var/list/allowed_ckeys = list("NightDawnFox")

/datum/element/smol/Destroy(force)
    LAZYNULL(allowed_ckeys)

    return ..()

/datum/element/smol/Attach(datum/target)
	. = ..()

	if(!isliving(target))
		return ELEMENT_INCOMPATIBLE

    RegisterSignal(target, COMSIG_MOB_RUN_EXAMINATE, PROC_REF(on_examine))

/datum/element/smol/Detach(atom/movable/source)
	UnregisterSignal(source, COMSIG_MOB_RUN_EXAMINATE)

	return ..()

/datum/element/smol/proc/on_examine(mob/source, mob/living/target, list/result)
    SIGNAL_HANDLER

    if(!istype(target) || !target.ckey)
        return

    INVOKE_ASYNC(src, PROC_REF(make_them_smol), target, result)

/datum/element/smol/proc/make_them_smol(mob/living/target, list/result)
    if(!LAZYIN(allowed_ckeys, target.ckey) || !is_admin(target))
        return

    LAZYADD(result, "Congratulations, you made them smol!")
    target.update_transform(-0.5)


    
