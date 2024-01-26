/// One use AI card which downloads a ghost as a syndicate AI to put in your MODsuit
/obj/item/aicard/syndie
	name = "intelliCard-辛迪AI人格芯片"
	desc = "存储AI人格的芯片，Nanotrasen忘记申请专利了，所以辛迪加自己做了个山寨品!"
	icon = 'icons/obj/aicards.dmi'
	icon_state = "syndicard"
	base_icon_state = "syndicard"
	item_flags = null
	force = 7

/obj/item/aicard/syndie/loaded
	/// Set to true while we're waiting for ghosts to sign up
	var/finding_candidate = FALSE

/obj/item/aicard/syndie/loaded/examine(mob/user)
	. = ..()
	. += span_notice("This one has a little S.E.L.F. insignia on the back, and a label next to it that says 'Activate for one FREE aligned AI! Please attempt uplink reintegration or ask your employers for reimbursal if AI is unavailable or belligerent.")

/obj/item/aicard/syndie/loaded/attack_self(mob/user, modifiers)
	if(!isnull(AI))
		return ..()
	if(finding_candidate)
		balloon_alert(user, "loading...")
		return TRUE
	finding_candidate = TRUE
	to_chat(user, span_notice("Connecting to S.E.L.F. dispatch..."))
	procure_ai(user)
	finding_candidate = FALSE
	return TRUE

/// Sets up the ghost poll
/obj/item/aicard/syndie/loaded/proc/procure_ai(mob/user)
	var/datum/antagonist/nukeop/op_datum = user.mind?.has_antag_datum(/datum/antagonist/nukeop,TRUE)
	if(isnull(op_datum))
		balloon_alert(user, "invalid access!")
		return

	var/datum/callback/to_call = CALLBACK(src, PROC_REF(on_poll_concluded), user, op_datum)
	AddComponent(/datum/component/orbit_poll, \
		ignore_key = POLL_IGNORE_SYNDICATE, \
		job_bans = ROLE_OPERATIVE, \
		to_call = to_call, \
		title = "Nuclear Operative Modsuit AI" \
	)

/// Poll has concluded with a ghost, create the AI
/obj/item/aicard/syndie/loaded/proc/on_poll_concluded(mob/user, datum/antagonist/nukeop/op_datum, mob/dead/observer/ghost)
	if(isnull(ghost))
		to_chat(user, span_warning("Unable to connect to S.E.L.F. dispatch. Please wait and try again later or use the intelliCard on your uplink to get your points refunded."))
		return

	// pick ghost, create AI and transfer
	var/mob/living/silicon/ai/weak_syndie/new_ai = new /mob/living/silicon/ai/weak_syndie(get_turf(src), new /datum/ai_laws/syndicate_override, ghost)
	// create and apply syndie datum
	var/datum/antagonist/nukeop/nuke_datum = new()
	nuke_datum.send_to_spawnpoint = FALSE
	new_ai.mind.add_antag_datum(nuke_datum, op_datum.nuke_team)
	new_ai.mind.special_role = "Syndicate AI"
	new_ai.faction |= ROLE_SYNDICATE
	// Make it look evil!!!
	new_ai.hologram_appearance = mutable_appearance('icons/mob/silicon/ai.dmi',"xeno_queen") //good enough
	new_ai.icon_state = resolve_ai_icon("hades")
	// Transfer the AI from the core we created into the card, then delete the core
	capture_ai(new_ai, user)
	var/obj/structure/ai_core/deactivated/detritus = locate() in get_turf(src)
	qdel(detritus)
	AI.control_disabled = FALSE
	AI.radio_enabled = TRUE
	do_sparks(4, TRUE, src)
	playsound(src, 'sound/machines/chime.ogg', 25, TRUE)
	return

/obj/item/aicard/syndie/loaded/upload_ai(atom/to_what, mob/living/user)
	. = ..()
	if (!.)
		return
	visible_message(span_warning("The expended card incinerates itself."))
	do_sparks(3, cardinal_only = FALSE, source = src)
	new /obj/effect/decal/cleanable/ash(get_turf(src))
	qdel(src)

/// Upgrade disk used to increase the range of a syndicate AI
/obj/item/computer_disk/syndie_ai_upgrade
	name = "AI interaction range upgrade"
	desc = "A NT data chip containing information that a syndiCard AI can utilize to improve its wireless interfacing abilities. Simply slap it on top of an intelliCard, MODsuit, or AI core and watch it do its work! It's rumoured that there's something 'pretty awful' in it."
	icon = 'icons/obj/antags/syndicate_tools.dmi'
	icon_state = "something_awful"
	max_capacity = 1000
	w_class = WEIGHT_CLASS_NORMAL

/obj/item/computer_disk/syndie_ai_upgrade/pre_attack(atom/A, mob/living/user, params)
	var/mob/living/silicon/ai/AI
	if(isAI(A))
		AI = A
	else
		AI = locate() in A
	if(!AI || AI.interaction_range == INFINITY)
		playsound(src,'sound/machines/buzz-sigh.ogg',50,FALSE)
		to_chat(user, span_notice("Error! Incompatible object!"))
		return ..()
	AI.interaction_range += 2
	if(AI.interaction_range > 7)
		AI.interaction_range = INFINITY
	playsound(src,'sound/machines/twobeep.ogg',50,FALSE)
	to_chat(user, span_notice("You insert [src] into [AI]'s compartment, and it beeps as it processes the data."))
	to_chat(AI, span_notice("You process [src], and find yourself able to manipulate electronics from up to [AI.interaction_range] meters!"))
	qdel(src)
