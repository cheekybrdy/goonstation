
/datum/lifeprocess/breath
	var/breathtimer = 0
	var/breathtimerstage = 0
	var/breathtimernotifredundant = 0
	var/breathstate = 0

	proc/update_breath_hud(datum/organ_status/lung/status_updates)
		src.human_owner?.hud.update_breathing_indicators(status_updates)
		src.critter_owner?.hud.update_breathing_indicators(status_updates)

	process(var/datum/gas_mixture/environment)
		if(isdead(owner))
			return ..()

		//special (read: stupid) manual breathing stuff. weird numbers are so that messages don't pop up at the same time as manual blinking ones every time
		if (manualbreathing && human_owner)
			breathtimer += get_multiplier()
			var/datum/organ_status/lung/status_updates = new

			switch(breathtimer)
				if (0 to 15)
					breathe(environment)
					breathtimerstage = 0
					breathtimernotifredundant = 0
				if (15 to 34)
					; // this statement is intentionally left blank
				if (34 to 51)
					if (prob(5)) owner.emote("gasp")
					if (!breathtimernotifredundant)
						breathtimerstage = 1
				if (52 to 61)
					status_updates.show_oxy_indicator = TRUE
					owner.take_oxygen_deprivation(breathtimer/12)
					if (breathtimernotifredundant < 2)
						breathtimerstage = 2
				if (62 to INFINITY)
					status_updates.show_oxy_indicator = TRUE
					owner.take_oxygen_deprivation(breathtimer/6)
					if (breathtimernotifredundant < 3)
						breathtimerstage = 3
			switch(breathtimerstage)
				if (0)
					; // this statement is intentionally left blank
				if (1)
					boutput(owner, SPAN_ALERT("You need to breathe!"))
					breathtimernotifredundant = 1
				if (2)
					boutput(owner, SPAN_ALERT("Your lungs start to hurt. You really need to breathe!"))
					breathtimernotifredundant = 2
				if (3)
					boutput(owner, SPAN_ALERT("Your lungs are burning and the need to take a breath is almost unbearable!"))
					breathtimernotifredundant = 3
			breathtimerstage = 0
			src.human_owner.hud.update_breathing_indicators(status_updates)
		else // plain old automatic breathing
			breathe(environment)

		if (istype(owner.loc, /obj/))
			var/obj/location_as_object = owner.loc
			location_as_object.handle_internal_lifeform(owner, 0, get_multiplier())
		..()

	proc/breathe(datum/gas_mixture/environment)
		var/mult = get_multiplier()
		var/datum/organ_status/lung/status_updates = new

		var/atom/underwater = 0
		var/bubble_breathing = FALSE
		if (isturf(owner.loc))
			var/turf/T = owner.loc
			if (istype(T, /turf/space/fluid))
				//this is potentially slow but I think still better than forcing bubbles to register and unregister from turfs
				var/obj/bubble/bubble = locate() in T
				if (bubble && bubble.scale >= 0.4)
					environment = bubble.air_contents
					bubble_breathing = TRUE
				else
					underwater = T
			else if (T.active_liquid)
				var/obj/fluid/F = T.active_liquid

				var/depth_to_breathe_from = length(depth_levels)
				if (owner.lying)
					depth_to_breathe_from = depth_levels.len-1

				if (F.amt >= depth_levels[depth_to_breathe_from])
					underwater = F
					if (owner.is_submerged != 4)
						owner.show_submerged_image(4)

			else if (T.active_airborne_liquid)
				var/exception = ismiasmaimmune(owner) ? "miasma" : null
				if (!issmokeimmune(owner))
					//underwater = T.active_airborne_liquid
					var/obj/fluid/F = T.active_airborne_liquid
					F.force_mob_to_ingest(owner, mult, exception)
				else
					if (!owner.clothing_protects_from_chems())
						var/obj/fluid/airborne/F = T.active_airborne_liquid
						F.just_do_the_apply_thing(owner, mult, hasmask = 1, exception = exception)

		else if (islivingobject(owner.loc))
			src.update_breath_hud(status_updates)
			return // no breathing inside possessed objects
		else if (istype(owner.loc, /obj/machinery/atmospherics/unary/cryo_cell))
			src.update_breath_hud(status_updates)
			return
		else if (istype(owner.loc, /obj/machinery/bathtub) && owner.lying)
			var/obj/machinery/bathtub/B = owner.loc
			if (B.reagents.total_volume > B.suffocation_volume)
				var/obj/fluid/F = new // used for underwater breathing check
				F.reagents = owner.loc.reagents
				underwater = F

		//if (istype(loc, /obj/machinery/clonepod)) return

		if (HAS_ATOM_PROPERTY(owner, PROP_MOB_REBREATHING))
			src.update_breath_hud(status_updates)
			if(owner.losebreath)
				owner.losebreath -= (1.3 * mult) // base losebreath recovery
			return

		// Changelings generally can't take OXY/LOSEBREATH damage...except when they do.
		// And because they're excluded from the breathing procs, said damage didn't heal
		// on its own, making them essentially mute and perpetually gasping for air.
		// Didn't seem like a feature to me (Convair880).
		// If you have the breathless effect, same deal - you'd never heal oxy damage
		// If your mutant race doesn't need oxygen from breathing, ya no losebreath
		// so, now you do
		if (ischangeling(owner) || HAS_ATOM_PROPERTY(owner, PROP_MOB_BREATHLESS))
			src.update_breath_hud(status_updates)
			if (owner.losebreath)
				owner.losebreath = 0
			if (owner.get_oxygen_deprivation())
				owner.take_oxygen_deprivation(-50 * mult)
			return

		if (underwater)
			if (human_owner?.mutantrace && human_owner?.mutantrace.aquatic)
				src.update_breath_hud(status_updates)
				return
			if(human_owner?.hasStatus("aquabreath"))
				src.update_breath_hud(status_updates)
				return
			if (prob(25) && owner.losebreath > 0)
				boutput(owner, SPAN_ALERT("You are drowning!"))

		var/datum/gas_mixture/breath = null
		// HACK NEED CHANGING LATER
		//if (src.oxymax == 0 || (breathtimer > 15))
		if (breathtimer > 15)
			owner.losebreath += (0.7 * mult)

		if (owner.grabbed_by && length(owner.grabbed_by))
			breath = get_breath_grabbed_by(BREATH_VOLUME * mult)

		if (!breath)
			if (owner.losebreath>0) //Suffocating so do not take a breath
				owner.losebreath -= (1.3 * mult)
				owner.losebreath = max(owner.losebreath,0)
				if (prob(75)) //High chance of gasping for air
					if (underwater)
						owner.emote("gurgle")
					else
						owner.emote("gasp")
				if (isobj(owner.loc))
					var/obj/location_as_object = owner.loc
					location_as_object.handle_internal_lifeform(owner, 0, mult)
				if (owner.losebreath <= 0)
					boutput(owner, SPAN_NOTICE("You catch your breath."))
			else
				//First, check for air from internal atmosphere (using an air tank and mask generally)
				breath = get_breath_from_internal(BREATH_VOLUME * mult)

				//No breath from internal atmosphere so get breath from location
				if (!breath)
					if (isobj(owner.loc))
						var/obj/location_as_object = owner.loc
						breath = location_as_object.handle_internal_lifeform(owner, BREATH_VOLUME, mult)
					else if (isturf(owner.loc) || ismob(owner.loc))
						var/breath_moles = (TOTAL_MOLES(environment) * BREATH_PERCENTAGE * mult)
						breath = environment?.remove(breath_moles)

				else //Still give containing object the chance to interact
					underwater = 0 // internals override underwater state
					if (isobj(owner.loc))
						var/obj/location_as_object = owner.loc
						location_as_object.handle_internal_lifeform(owner, 0, mult)

		breath?.volume = BREATH_VOLUME * mult
		var/success = handle_breath(breath, underwater, mult = mult)

		if (breath && success) //only breathe out gas when we're not drowing
			if (bubble_breathing) //we don't want to spawn more bubbles if we're breathing from a bubble
				environment.merge(breath)
			else
				owner.loc.assume_air(breath)


	proc/get_breath_grabbed_by(volume_needed)
		. = null
		for(var/obj/item/grab/force_mask/G in owner.grabbed_by)
			. = G.get_breath(volume_needed)
			if (.)
				break

	proc/get_breath_from_internal(volume_needed)
		if (human_owner?.internal)
			if (!(human_owner.internal in owner.contents))
				human_owner?.internal = null
			if (!human_owner?.wear_mask || !(human_owner?.wear_mask.c_flags & MASKINTERNALS) )
				human_owner?.internal = null
			if (human_owner?.internal)
				if (human_owner?.internals)
					human_owner?.internals.icon_state = "internal1"
				for (var/obj/ability_button/tank_valve_toggle/T in human_owner?.internal.ability_buttons)
					T.icon_state = "airon"
				return human_owner?.internal.remove_air_volume(volume_needed)
			else
				if (human_owner?.internals)
					human_owner?.internals.icon_state = "internal0"

		return null

	///Return value is the number of lungs that successfully breathed
	proc/handle_breath(datum/gas_mixture/breath, var/atom/underwater = 0, var/mult = 1) //'underwater' really applies for any reagent that gets deep enough. but what ever
		var/datum/organ_status/lung/status_updates = new
		var/area/A = get_area(owner)
		if( A?.sanctuary || owner.nodamage )
			src.update_breath_hud(status_updates)
			if (owner.losebreath)
				owner.losebreath = 0
			if (owner.get_oxygen_deprivation())
				owner.take_oxygen_deprivation(-50 * mult)
			return
		// Looks like we're in space
		// or with recent atmos changes, in a room that's had a hole in it for any amount of time, so now we check src.loc
		if (underwater || !breath || (TOTAL_MOLES(breath) == 0))
			if (istype(owner.loc, /turf/space))
				owner.take_oxygen_deprivation(6 * mult)
			else
				owner.take_oxygen_deprivation(3 * mult)
			status_updates.show_oxy_indicator = TRUE

			//consume some reagents if we drowning
			if (underwater && (owner.get_oxygen_deprivation() > 40 || underwater.type == /obj/fluid/airborne))
				if (istype(underwater,/obj/fluid))
					var/obj/fluid/F = underwater
					F.force_mob_to_ingest(owner, mult)// * mult
				else if (istype(underwater, /turf/space/fluid))
					var/turf/space/fluid/F = underwater
					F.force_mob_to_ingest(owner, mult)// * mult

			src.update_breath_hud(status_updates)
			return 0

		if (owner.health < 0 || (human_owner?.organHolder && human_owner?.organHolder.get_working_lung_amt() == 0)) //We aren't breathing.
			src.update_breath_hud(status_updates)
			return 0

		var/datum/gas_mixture/left_breath = breath.remove_ratio(0.5)
		var/datum/gas_mixture/right_breath = breath.remove_ratio(1) // the rest
		left_breath.volume = breath.volume / 2
		right_breath.volume = breath.volume / 2

		var/success = 0
		if (!human_owner?.organHolder?.left_lung?.broken)
			success += human_owner?.organHolder?.left_lung?.breathe(left_breath, underwater, mult, status_updates)
		if (!human_owner?.organHolder?.right_lung?.broken)
			success += human_owner?.organHolder?.right_lung?.breathe(right_breath, underwater, mult, status_updates)

		breath.merge(left_breath)
		breath.merge(right_breath)

		src.update_breath_hud(status_updates)

		for(var/emote in status_updates.emotes)
			human_owner?.emote(emote)

		return success

