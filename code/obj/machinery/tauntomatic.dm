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
	emagged = FALSE
	var/cooldown = 30 MINUTES
	var/mode = 0 // 0 is idle, 1 is warming up, 2 is for when the broadcast is sent, 3 is cooldown
	var/timer = 1 MINUTE
	emagged = FALSE
	var/start_time = null
	var/taunt_amount = null

/obj/machinery/tauntomatic/attack_hand(mob/user)
	. = ..()
	if(!emagged)
		taunt_amount = tgui_input_list(user,"Set insult intensity", taunt_levels)
	else
		taunt_amount = tgui_input_list(user,"Set insult intensity", taunt_levels + "REDACTED")
	if(tgui_alert(user, "Are you sure?", "Confirmation", list("Yes", "No")) == "Yes")
		mode = 1
		warmup()

/obj/machinery/tauntomatic/emag_act(var/mob/user, var/obj/item/card/emag/E)
	..()
	src.emagged = TRUE
	boutput(user, "The [src] emits some concerning sparks")
	var/obj/itemspecialeffect/conc/C = new /obj/itemspecialeffect/conc
	C.setup(src.turf)
	logTheThing(LOG_STATION, src, "[src] was emagged by [key_name(user)], adding the extra spawn option.")
	return 1

/obj/machinery/tauntomatic/warmup(var/taunt_amount)
	playsound(src.loc, 'sound/vox/orkinsult2.ogg', 75, 1)
	start_time = world.timeofday
	if(taunt_amount != taunt_levels[1] || "REDACTED")
		timer = 3 MINUTES
	else if(taunt_amount = taunt_levels[0])
		timer = 1 MINUTE
	else
		timer = 5 MINUTES // emag timer
	process()

/obj/machinery/tauntomatic/process() // Totally not stolen flock relay code
	if(src.mode = 1)
		var/elapsed = getTimeInSecondsSinceTime(src.start_time)
		if (!src.mode = 2)
			src.info_tag.set_info_tag("Completion time: [round(src.timer - elapsed)] seconds")
		else
			src.info_tag.set_info_tag("Transmitting")
		if(!rand(0,49) && mode = 1)
			playsound(src.loc, 'sound/vox/orkinsult2.ogg', 100, 1)
			playsound(src.loc, 'sound/machines/keypress.ogg', 50, 1)
		if(elapsed >= charge_time_length/2) // halfway point, start doing more
			SPAWN(0)
				for(var/mob/M in range(25))
					if(prob(20))
						M.playsound_local(M, "sound/voice/binsultbeep.ogg", 20, 1)
						if(prob(50))
							boutput(M, "What on earth is causing all that foul language?")
		if(elapsed >= charge_time_length)
			text_generate


/obj/machinery/tauntomatic/text_generate()
	title = TAUNTOMATIC_PICK(title_header) + TAUNTOMATIC_PICK(organisations_1)
	paragraph_1 =
	fire()

/obj/machinery/tauntomatic/fire()
	if (taunt_amount != taunt_levels[0])
		var/summoner = new/datum/random_event/major/player_spawn/antag/antagonist_pest
	else if (taunt_amount = taunt_levels[1])
		var/summoner = new/datum/random_event/major/player_spawn/antag/antagonist/taunt
		if(taunt_amount != taunt_levels[1])
			summoner.threat_type = 1
		else
			summoner.threat_type = 0
	else
