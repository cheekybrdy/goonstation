/// Brazier \\\
/// Balance numbers are in defines/power.dm.
/obj/brazier
	name = "Offering Brazier"
	desc = "A holy brazier for communicating and sending offerings to a pantheon of Gods."
	icon = 'icons/obj/pantheon/brazier.dmi'
	icon_state = "brazier-d-unlit"
	event_handler_flags = USE_FLUID_ENTER // For bartender drink offerings.
	var/brazier_id = null // In case someone orders more.
	var/pantheon = null
	var/pantheon_power = 0 // Math for this is in defines.
	var/pantheon_level = 0
	var/pantheon_owner = null
	var/fire_colour

// /obj/brazier/ui_interact(mob/user, datum/tgui/ui)
//   ui = tgui_process.try_update_ui(user, src, ui)
//   if(!ui)
//     ui = new(user, src, "Brazier")
//     ui.open()

// /obj/brazier/ui_data(mob/user)
//   . = list(
//     "pantheon_power" = pantheon_power,
//     "set_pantheon" = pantheon,
// 	"pantheon_level" = pantheon_level,
// 	"pantheon_goal" = "PANTHEON_THRESHOLD_" + pantheon_level++
//   )

// /obj/brazier/ui_act(action, params)
//   . = ..()
//   if (.)
//     return
//   if(action == "select_pantheon")
//     var/new_color = params["color"]
//     if(!(color in allowed_coors))
//       return FALSE
//     color = new_color
//     . = TRUE
//   update_icon()
