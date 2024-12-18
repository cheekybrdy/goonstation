/// Brazier
/// Balance numbers are in defines/power.dm.
/obj/brazier
	name = "Offering Brazier"
	desc = "A holy brazier for communicating and sending offerings to a pantheon of Gods."
	icon = 'icons/obj/pantheon/offerings/brazier.dmi'
	icon_state = "brazier-d-unlit"
	event_handler_flags = USE_FLUID_ENTER | TGUI_INTERACTIVE // For bartender drink offerings.
	anchored = UNANCHORED
	density = TRUE
	var/brazier_id = null // In case someone orders more.
	var/chapel_locked = FALSE
	var/pantheon = null
	var/pantheon_power = 0 // Math for this is in defines.
	var/pantheon_level = 0
	var/pantheon_owner = null
	var/image/fire_overlay = null
	var/list/buyable_items = list()
	HELP_MESSAGE_OVERRIDE({"The brazier can only be moved if unwrenched on harm intent."})

	New()
		START_TRACKING
		brazier_id = length(by_type[/obj/brazier]) // I'd assume this could break if someone crushers one
		..()
		if(!pantheon)
			return
		else // These aren't going to be set by default unless its a admin spawn type with the pantheon already decided
			buyable_items = list(new/datum/brazier_item)

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
			user.visible_message("<b>[user]</b> begins to [src.anchored ? "unbolt the [src.name] from" : "bolt the [src.name] to"] [get_turf(src)].")
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
    "set_pantheon" = pantheon,
	"pantheon_level" = pantheon_level,
	"pantheon_goal" = "PANTHEON_THRESHOLD_" + pantheon_level++
  )

/obj/brazier/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
   . = ..()
//   if (.)
//     return
//   if(action == "select_pantheon")
//     var/new_color = params["color"]
//     if(!(color in allowed_coors))
//       return FALSE
//     color = new_color
//     . = TRUE
   update_icon()

/obj/brazier/chaplain // Chapel brazier, gets faith bonuses and is locked to the chaplain so they have one to use as a latejoin if not sabotaged
	chapel_locked = TRUE
	anchored = ANCHORED
	New()
		..()
		desc += " This one is the chaplain's personal brazier, blessed so only they can set it up."

/datum/brazier_item // totally not stolen from the gang locker code.
	var/name = "commodity"	// Name of the item
	var/desc = "item"		//Description for item
	var/pantheon = ""			//This should be general category: weapon, clothing/armor, misc
	var/item_path = null 		// Type Path of the item
	var/price = 100 			//

// Use 	src.UpdateOverlays(fire_overlay, "fire_sprite_go_here")
