/datum/random_event/start/arrivelate
	name = "Late Arrival"
	customization_available = 0
	required_elapsed_round_time = 0

	admin_call(var/source)
		if (..())
			return

	event_effect(var/source)
		..()
		var/list/area/all_areas = get_accessible_station_areas()
		for(var/mob/living/carbon/human/H as anything in mobs)
			if(!H.mind && ROLE_NUKEOP || ROLE_NUKEOP_COMMANDER || ROLE_SALVAGER || ROLE_WIZARD && src.traitHolder.hasTrait("partyanimal") || src.traitHolder.hasTrait("sleepy") || src.traitHolder.hasTrait("pilot"))
				return
			H.loc = pick_landmark(LANDMARK_LATEJOIN)


