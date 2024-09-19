/datum/component/devour
    /// Which atom types you can devour
    var/list/allowed_types
    /// Blacklisted atom types to devour
    var/list/blacklisted_types
    /// How much time that will take to devour target
    var/devouring_time 
    /// Drops loc contents on dead
    var/drop_contents
    /// Contents can be dropped without gibbing
    var/drop_anyway
    /// Target health threshold, if corpse_only on FALSE you will devour him without dead stat
    var/health_threshold
    /// Can consume only dead target
    var/corpse_only
    /// Silences messages when TRUE
    var/silent
    /// If you still want to do attack without cancel when requirements to devour target met
    var/cancel_attack

/datum/component/devour/Initialize(
    list/allowed_types,
    list/blacklisted_types,
    devouring_time = 3 SECONDS,
    health_threshold,
    corpse_only = TRUE,
    drop_contents = TRUE,
    drop_anyway = FALSE,
    silent = FALSE,
    cancel_attack = TRUE
)
    if(!ismob(parent))
        return COMPONENT_INCOMPATIBLE
    src.allowed_types = allowed_types
    src.blacklisted_types = blacklisted_types
    src.health_threshold = health_threshold
    src.corpse_only = corpse_only
    src.drop_contents = drop_contents
    src.drop_anyway = drop_anyway
    src.silent = silent
    src.cancel_attack = cancel_attack

/datum/component/devour/RegisterWithParent()
    RegisterSignal(parent, COMSIG_MOB_PRE_UNARMED_ATTACK, PROC_REF(try_devour))
    RegisterSignal(parent, COMSIG_MOB_DEATH, PROC_REF(on_mob_death)) // register anyway for flexibility

/datum/component/devour/UnregisterFromParent()
    UnregisterSignal(parent, list(COMSIG_MOB_PRE_UNARMED_ATTACK, COMSIG_MOB_DEATH))

/datum/component/devour/proc/try_devour(atom/movable/atom, params)
    SIGNAL_HANDLER

    if(allowed_types && !is_type_in_list(atom, allowed_types))
        return
    if(blacklisted_types && is_type_in_list(atom, blacklisted_types))
        return

    if(isitem(atom))
        var/obj/item/item = atom
        if(item.anchored)
            return
    if(isliving(atom))
        var/mob/living/living = atom
        if(corpse_only && living.stat != DEAD)
            return
        if(health_threshold && living.health > health_threshold)
            return

    INVOKE_ASYNC(src, PROC_REF(devour), atom, params)
    if(!cancel_attack)
        return
    return COMPONENT_CANCEL_UNARMED_ATTACK

/datum/component/devour/proc/devour(atom/movable/atom, params)
    SEND_SIGNAL(parent, COMSIG_COMPONENT_PRE_DEVOUR_TARGET, atom, params)
    if(!silent)
        to_chat(parent, span_warning("Вы начинаете глотать [atom] целиком..."))
    if(devouring_time && !do_after(parent, devouring_time, atom, NONE))
        return
    if(SEND_SIGNAL(parent, COMSIG_COMPONENT_DEVOURING_TARGET, atom, params) & STOP_DEVOURING)
        return
    var/mob/mob = parent
    if(atom?.loc == mob)
        return
    if(!silent)
        playsound(parent, 'sound/misc/demon_attack1.ogg', 100, TRUE)
        mob.visible_message(span_warning("[mob] swallows [atom] whole!"))
    atom.extinguish_light()
    atom.forceMove(mob)
    SEND_SIGNAL(mob, COMSIG_COMPONENT_DEVOURED_TARGET, atom, params)

/datum/component/devour/proc/on_mob_death(gibbed)
    SIGNAL_HANDLER

    if(!drop_contents)
        return
    if(!drop_anyway && !gibbed)
        return
    var/mob/mob = parent
    for(var/atom/movable/atom in mob)
        atom.forceMove(mob.loc)
        if(prob(90))
            step(atom, pick(GLOB.alldirs))

