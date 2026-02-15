// For the machine that pisses the fuck out of people.
// Starts off with all the lists to randomise the taunts, machine itself is at line (TODO)
var/list/taunt_levels = "Pissy Preschooler", "I want to speak to your manager", "Space Geneva Convention Violating"
#define TAUNTOMATIC_PICK(WHAT) pick_string("tauntomatic.txt", WHAT)

/obj/machinery/tauntomatic
	name = "Nerdsky Tauntomatic 3000"
	desc = "A machine of mass trolling. Only answering to the Head of Security, Nerdsky using the tauntomatic can enrage every adversary within a lightyear with the most obscene of comments."
	icon_state = "tauntomatic"
	power_usage = 5
	req_access = list(access_maxsec)
	cooldown = 30 MINUTES
	mode = 0 // 0 is idle, 1 is warming up, 2 is for when the broadcast is sent, 3 is cooldown
	timer = 1 MINUTE
	emagged = FALSE

/obj/machinery/tauntomatic/attack_hand(mob/user)
	. = ..()
	if(!emagged)
		var/taunt_amount = tgui_input_list(user,"Set insult intensity", taunt_levels)
	else
		var/taunt_amount = tgui_input_list(user,"Set insult intensity", taunt_levels + "REDACTED")
	if(tgui_alert(user, "Are you sure?", "Confirmation", list("Yes", "No")) == "Yes")
		mode = 1
		warmup(taunt_amount)

/obj/machinery/tauntomatic/emag_act(var/mob/user, var/obj/item/card/emag/E)
	..()
	src.emagged = TRUE
	if (isnull(src.occupant))
	logTheThing(LOG_STATION, src, "[src] was emagged by [key_name(user)], adding the extra spawn option.")
	return 1

/obj/machinery/tauntomatic/warmup(var/taunt_amount)
	playsound(src.loc, 'sound/vox/orkinsult2.ogg', 75, 1)
	if(taunt_amount = taunt_levels[1])

/obj/machinery/tauntomatic/text_generate(var/taunt_amount)
	title = TAUNTOMATIC_PICK(title_header) + TAUNTOMATIC_PICK(organisations_1)
	fire(taunt_amount)

/obj/machinery/tauntomatic/fire(var/taunt_amount)
	if (taunt_amount != taunt_levels[0])
		var/summoner = new/datum/random_event/major/player_spawn/antag/antagonist_pest
	else if (taunt_amount = taunt_levels[1])
		var/summoner = new/datum/random_event/major/player_spawn/antag/antagonist/taunt
		if(taunt_amount != taunt_levels[1])
			summoner.threat_type = 1
		else
			summoner.threat_type = 0
	else
