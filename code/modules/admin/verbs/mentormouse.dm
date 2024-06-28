/client/proc/MentorMouse()

	set name = "Mentor Mouse"
	set category = "Admin"

	if(!check_rights(R_MENTOR|R_ADMIN))
		return

	var/mob/living/simple_animal/mouse/mentor/M = usr
	if(istype(M))
		CreateMentorMouse(TRUE)
		return

	CreateMentorMouse()

/client/proc/CreateMentorMouse(IsMouse = FALSE)
	if(IsMouse)
		var/mob/living/simple_animal/mouse/mentor/M = usr
		playsound(get_turf(M), 'sound/effects/phasein.ogg', 100, 1)
		qdel(M)
		return

	var/mob/dead/observer/ghost = usr
	if(!istype(ghost))
		return

	if(alert("Are you sure want to spawn as a mentor mouse? That action will turn off respawnability!",,"Yes", "No") == "Yes")
		var/mob/living/simple_animal/mouse/mentor/M = new(usr.loc)
		M.key = ghost.key
		M.verbs -= /mob/living/verb/ghost // idk how to fix qdel in ghostize, just use Mentor Mouse verb again..
		GLOB.non_respawnable_keys += M.ckey

