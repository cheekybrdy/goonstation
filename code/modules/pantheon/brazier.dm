/// Brazier
/// Balance numbers are in defines/power.dm.
/obj/brazier
	name = "Offering Brazier"
	desc = "A holy brazier for communicating and sending offerings to a pantheon of Gods."
	icon = 'icons/obj/pantheon/offerings/brazier.dmi'
	icon_state = "brazier-divine"
	event_handler_flags = USE_FLUID_ENTER | TGUI_INTERACTIVE | NO_GHOSTCRITTER // For bartender drink offerings.
	anchored = UNANCHORED
	density = TRUE
	var/datum/pantheon/pantheon = null
	var/chapel_locked = FALSE
	var/whitelist_mode = FALSE
	var/pantheon_type = null
	var/image/fire_overlay = null
	var/list/buyable_items = list()
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
    "pantheon_power" = pantheon.pantheon_power,
    "set_pantheon" = pantheon_type,
	"whitelisted" = whitelist_mode,
  )

/obj/brazier/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	var/denied = TRUE
	. = ..()
	if (.)
		return
	if(action == "select_pantheon")
		if (chapel_locked && usr.mind.assigned_role != "Chaplain")
			boutput(usr, SPAN_ALERT("This is the chaplain's brazier, only they can use it!"))
			return
		else if (pantheon.leader)
			logTheThing(LOG_ADMIN, src, "Someone is somehow trying to change a pantheon's type that's already setup.</b>")
			logTheThing(LOG_STATION, src, "[usr], attempted to create a pantheon using a already setup brazier.")
		else
			pantheon.pantheon_type = params["pantheon"]
			#ifdef SECRETS_ENABLED
			if(!(pantheon.pantheon_type in allowed_pantheons))
				return FALSE
			#endif
			icon_state = "brazier-[pantheon_type]"
			buyable_items = list(
				standard_offerings,
				pantheon_type + "_offerings")
			playsound(src.loc, 'sound/effects/spray.ogg', 50, 1)
			flick(src.UpdateOverlays(fire_overlay, "brazier-[pantheon_type]-flaring"), src)
			src.UpdateOverlays(fire_overlay, "brazier-[pantheon_type]-resting")
			boutput(usr, SPAN_ALERT("The brazier swirls to life in a eruption of divine fire!"))
			logTheThing(LOG_STATION, src, "[usr], setup a pantheon of [pantheon.pantheon_type].")
			. = TRUE
	update_icon()
	for (var/datum/mind/M in pantheon.members)
		if (usr.mind == M)
			denied = FALSE
	if(action == "buy_item")
		if (denied)
			boutput(usr, SPAN_ALERT("You are not a member of this pantheon, you cannot conjure items from it."))
			return
		var/datum/brazier_item/PI = buyable_items
		if (locate(PI) in buyable_items)
			if (PI.price <= src.pantheon.pantheon_power)
				PI.pantheon = pantheon // Changes the item to a more specific type
				src.pantheon.pantheon_power -= PI.price
				flick(src.UpdateOverlays(fire_overlay, "brazier-[pantheon_type]-flaring"), usr)
				playsound(src.loc, 'sound/effects/spray.ogg', 50, 1)
				boutput(usr, SPAN_NOTICE("You purchase [PI.name] for [PI.price]. Remaining power = [src.pantheon.pantheon_power] points."))
				logTheThing(LOG_STATION, src, "[usr] got [PI.name] at their pantheon's brazier.")
				if (!PI.on_purchase(src, usr))
					new PI.item_path(src.loc)
				pantheon.items_purchased[PI.item_path]++
				updateDialog()
		else
			boutput(usr, SPAN_ALERT("Insufficient power."))
	if(action == "join_pantheon")
		if (usr.mind.pantheon)
			boutput(usr, SPAN_ALERT("You are already a member of a pantheon!"))
			return
		else if (src.whitelist_mode)
			boutput(usr, SPAN_ALERT("This pantheon is currently private, a request has been sent to the leader."))
			boutput(pantheon.leader, SPAN_ALERT("[usr] has requested to join your pantheon! Accept or Decline their invitation at the brazier!"))
			pantheon.pantheon_applicants += usr
		else
			pantheon.members += usr.mind
			flick(src.UpdateOverlays(fire_overlay, "brazier-[pantheon_type]-flaring"), src)
			playsound(src.loc, 'sound/effects/spray.ogg', 50, 1)
			boutput(usr, SPAN_ALERT("You are now a member of this pantheon! Praise be to the divine."))
			logTheThing(LOG_STATION, src, "[usr] joined [pantheon.leader]'s pantheon.")


/obj/brazier/chaplain // Chapel brazier, gets faith bonuses and is locked to the chaplain so they have one to use as a latejoin if not sabotaged
	chapel_locked = TRUE
	anchored = ANCHORED
	New()
		..()
		desc += " This one is the chaplain's personal brazier, blessed so only they can set it up."
