/// Brazier
/// Balance numbers are in defines/power.dm.
/obj/brazier
	name = "Offering Brazier"
	desc = "A holy brazier for communicating and sending offerings to a pantheon of Gods."
	icon = 'icons/obj/pantheon/offerings/brazier.dmi'
	icon_state = "brazier-divine-unlit"
	event_handler_flags = USE_FLUID_ENTER | TGUI_INTERACTIVE | NO_GHOSTCRITTER // For bartender drink offerings.
	anchored = UNANCHORED
	density = TRUE
	var/datum/pantheon/pantheon = null
	var/chapel_locked = FALSE
	var/pantheon_type = null
	var/pantheon_power = 0 // Math for this is in defines.
	var/image/fire_overlay = null
	var/list/buyable_items = list()
	var/list/pantheon_applicants = list()
	HELP_MESSAGE_OVERRIDE({"The brazier can only be moved if unwrenched on harm intent."})

	New()
		START_TRACKING
		..()
		if(!pantheon_type)
			return
		else // These aren't going to be set by default unless its a admin spawn type with the pantheon already decided
			buyable_items = list()

	disposing(var/uncapture = 1)
		STOP_TRACKING
		..()

	examine()
		. = ..()
		. += ""

	attackby(obj/item/W, mob/user)
		if(!isalive(user))
			boutput(user, SPAN_ALERT("Not when you're incapacitated."))
			return
		if(!isliving(user))
			boutput(user, SPAN_ALERT("You're too, er, dead."))
			return
		if (iswrenchingtool(W) && user.a_intent == INTENT_HARM)
			if (istype(get_turf(src), /turf/space))
				if (user)
					user.show_text("What exactly are you gunna secure [src] to?", "red")
				return
			playsound(src.loc, 'sound/items/Ratchet.ogg', 50, 1)
			user.visible_message("<b>[user]</b> bePIns to [src.anchored ? "unbolt the [src.name] from" : "bolt the [src.name] to"] [get_turf(src)].")
			SETUP_GENERIC_ACTIONBAR(user, src, 5 SECONDS, /obj/brazier/proc/toggle_bolts, list(user), W.icon, W.icon_state,"", null)
			return
		add_fingerprint(user)

	attack_hand(var/mob/user)
		if(!isalive(user))
			boutput(user, SPAN_ALERT("Not when you're incapacitated."))
			return
		if(!isliving(user))
			boutput(user, SPAN_ALERT("You're too, er, dead."))
			return
		add_fingerprint(user)

	proc/toggle_bolts(var/mob/user)
		user.visible_message("<b>[user]</b> [src.anchored ? "loosens" : "tightens"] the floor bolts of [src].[istype(src.loc, /turf/space) ? " It doesn't do much, though, since [src] is in space and all." : null]")
		src.anchored = !src.anchored
		logTheThing(LOG_STATION, user, "[src.anchored ? "unanchored" : "anchored"] [log_object(src)] at [log_loc(src)]")

/obj/brazier/ui_interact(mob/user, datum/tgui/ui)
  ui = tgui_process.try_update_ui(user, src, ui)
  if(!ui)
    ui = new(user, src, "Brazier")
    ui.open()

/obj/brazier/ui_data(mob/user)
  . = list(
    "pantheon_power" = pantheon_power,
    "set_pantheon" = pantheon_type,
  )

/obj/brazier/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if (.)
    	return
	if(action == "select_pantheon")
		if(chapel_locked && src.mind.assigned_role != "Chaplain")
			boutput(usr, SPAN_ALERT("This is the chaplain's brazier, only they can use it!"))
			return
		else if (pantheon_type)
			logTheThing(LOG_ADMIN, src, "Someone is somehow trying and able to try and change a pantheon's type that's already setup.</b>")
			logTheThing(LOG_STATION, src, "[src.user], attempted to create a pantheon using a already setup brazier.")
		else
			pantheon.pantheon_type = params["pantheon"]
			if(!(pantheon.pantheon_type in allowed_pantheons))
				return FALSE
			pantheon = new_pantheon
			icon_state = "brazier-[pantheon_type]"
			buyable_items = list(
				list(standard_offerings)
				list("[pantheon_type]_offerings"))
			playsound(src.loc, 'sound/effects/spray.ogg', 50, 1)
			flick(src.UpdateOverlays(fire_overlay, "[brazier.icon_state]-flaring"))
			src.UpdateOverlays(fire_overlay, "[brazier.icon_state]-resting")
			boutput(usr, SPAN_ALERT("The brazier swirls to life in a eruption of divine fire!"))
			logTheThing(LOG_STATION, src, "[src.user], setup a pantheon of [pantheon.pantheon_type]. ")
			. = TRUE
	update_icon()
	if(action == "buy_item")
		if (usr.get_pantheon() != src.pantheon)
			boutput(usr, SPAN_ALERT("You are not a member of this pantheon, you cannot purchase items from it."))
			return
		var/datum/pantheon_item/PI = buyable_items
		if (locate(PI) in buyable_items)
			if (PI.price <= src.pantheon.pantheon_points)
				src.pantheon.pantheon_points -= PI.price
				flick(src.UpdateOverlays(fire_overlay, "[brazier.icon_state]-flaring"))
				playsound(src.loc, 'sound/effects/spray.ogg', 50, 1)
				boutput(usr, SPAN_NOTICE("You purchase [PI.name] for [PI.price]. Remaining divinity = [src.pantheon.pantheon_points] points."))
				logTheThing(LOG_STATION, src, "[src.user] got [PI.name] at their pantheon's brazier.")
				if (!PI.on_purchase(src, usr))
					new PI.item_path(src.loc)
				pantheon.items_purchased[PI.item_path]++
				updateDialog()
		else
			boutput(usr, SPAN_ALERT("Insufficient power."))
	if(action == "join_pantheon")
		if (usr.get_pantheon() == src.pantheon)
			boutput(usr, SPAN_ALERT("You are already a member of a pantheon!"))
			return
		else if (src = whitelisted)
			boutput(usr, SPAN_ALERT("This pantheon is currently private, a request has been sent to the leader."))
			boutput(pantheon.pantheon_owner, SPAN_ALERT("[src.user] has requested to join your pantheon! Accept or Decline their invitation at the brazier!"))
			pantheon_applicants += src.user
		else
			pantheon.members += src.user
			flick(src.UpdateOverlays(fire_overlay, "[brazier.icon_state]-flaring"))
			playsound(src.loc, 'sound/effects/spray.ogg', 50, 1)
			boutput(usr, SPAN_ALERT("You are now a member of this pantheon! Praise be to the divine."))


/obj/brazier/chaplain // Chapel brazier, gets faith bonuses and is locked to the chaplain so they have one to use as a latejoin if not sabotaged
	chapel_locked = TRUE
	anchored = ANCHORED
	New()
		..()
		desc += " This one is the chaplain's personal brazier, blessed so only they can set it up."

/datum/brazier_item // totally not stolen from the pantheon locker code.
	var/name = "commodity"	// Name of the item
	var/desc = "item"		//Description for item
	var/pantheon = ""			//This should be general category: weapon, clothing/armor, misc
	var/item_path = null 		// Type Path of the item
	var/price = 100 			//

// Use 	src.UpdateOverlays(fire_overlay, "fire_sprite_go_here")
//src.icon_state = "[mail.icon_state]-b"
